# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Search for and read dataform.json files in the input dataform repositories
data "github_repository_file" "dataform_config" {
  for_each   = var.dataform_repositories
  repository = local.git_path[each.key]
  branch     = each.value.branch
  file       = "dataform.json"
}

module "aef-dataform-service-account" {
  source            = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/iam-service-account"
  project_id        = var.project
  name              = "aef-dataform-service-account"
  iam_project_roles = {
    "${var.project}" = [
      "roles/dataform.serviceAgent",
      "roles/iam.serviceAccountTokenCreator",
      "roles/bigquery.admin"
    ]
  }
}

#In order to enable dataform to communicate with a 3P GIT provider, an access token must be generated and stored as a secret on GCP
module "secrets" {
  for_each   = local.dataform_repositories
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/secret-manager"
  project_id = var.project
  secrets    = {
    "${each.value.secret_name}" = {
    }
  }
  versions = {
    "${each.value.secret_name}" = {
      "${each.value.secret_version}" = {
        enabled = true,
        data    = var.dataform_repositories_git_token
      }
    }
  }
  iam = {
    "${each.value.secret_name}" = {
      "roles/secretmanager.secretAccessor" = [
        "serviceAccount:service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com",
        module.aef-dataform-service-account.iam_email
      ]
    }
  }
}

resource "google_service_account_iam_member" "dataform_permissions" {
  for_each = toset(["roles/iam.serviceAccountTokenCreator", "roles/iam.serviceAccountUser"])
  service_account_id = module.aef-dataform-service-account.id
  role    = each.key
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
  depends_on = [module.dataform_with_external_repos, module.secrets]
}

#creates a dataform repository with a remote repository attached to it.
module "dataform_with_external_repos" {
  for_each                   = var.create_dataform_repositories ? local.dataform_repositories : {}
  source                     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/dataform-repository"
  project_id                 = var.project
  name                       = each.key
  region                     = var.region
  service_account = module.aef-dataform-service-account.email
  remote_repository_settings = {
    url             = each.value.remote_repo_url
    branch          = each.value.branch
    secret_name     = each.value.secret_name
    secret_version  = module.secrets[each.key].version_ids["${local.dataform_repositories[each.key].secret_name}:${local.dataform_repositories[each.key].secret_version}"]
  }
}

/* Create datasets defined via dataform.json variables if any, it should include 3 variables for each dataset with next format:
    "dataset_id_<DATASET_IDENTIFIER>":"<YOUR_DATASET_NAME>",
    "dataset_projectid_<DATASET_IDENTIFIER>":"<YOUR_DATASET_PROJECT>",
    "dataset_location_<DATASET_IDENTIFIER>":"<YOUR_DATASET_LOCATION>",
*/
resource "google_bigquery_dataset" "dataform_datasets" {
  for_each    = var.create_dataform_datasets ? { for k, v in local.all_created_datasets : k => v if v.from_dataform } : {}
  dataset_id  = each.value.dataset_id
  project     = each.value.project
  location    = each.value.location
  description = each.value.description
}

#Run the dataform scripts found in the repositories
resource "null_resource" "install_dataform_dependencies" {
  for_each = var.compile_dataform_repositories ? local.dataform_repositories : {}
  provisioner "local-exec" {
    command = <<EOF
      python3 -m venv aef_dataform_executor
      source aef_dataform_executor/bin/activate
      pip install google-api-core
      pip install google-cloud-dataform
      pip install google-cloud-asset
    EOF
  }
  depends_on = [google_service_account_iam_member.dataform_permissions, module.dataform_with_external_repos, null_resource.run_metadata_deployer]
  triggers   = {
    always_run = timestamp()
  }
}

data "external" "dataform_deploy" {
  for_each = var.compile_dataform_repositories ? local.dataform_repositories : {}

  program = ["aef_dataform_executor/bin/python3", "../cicd-deployers/dataform_runner.py",
    "--project_id", var.project,
    "--project_number", data.google_project.project.number,
    "--location", var.region,
    "--repository", each.key,
    "--tags", "ddl",
    "--execute", var.execute_dataform_repositories,
    "--branch", each.value.branch
  ]
  depends_on = [null_resource.install_dataform_dependencies,google_service_account_iam_member.dataform_permissions]
}