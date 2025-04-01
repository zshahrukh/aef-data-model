# Copyright 2024 Google LLC
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

locals {

  git_repo_url_map = {
    for repo_key, repo_settings in var.dataform_repositories :
    repo_key => repo_settings.remote_repo_url
  }

  repo_prefix = {
    for repo_key, repo_url in local.git_repo_url_map :
    repo_key => replace(repo_url, "/.*/(.*)/.*\\.git/", "$1")
  }

  repo_name = {
    for repo_key, repo_url in local.git_repo_url_map :
    repo_key => replace(repo_url, "/.*/(.*)\\.git/", "$1")
  }

  git_path = {
    for repo_key in keys(local.git_repo_url_map) :
    repo_key => "${local.repo_prefix[repo_key]}/${local.repo_name[repo_key]}"
  }

  dataform_repositories = {
    for repo_name, repo_config in var.dataform_repositories :
    repo_name => merge(
      repo_config,
      {
        secret_name = "${repo_name}_secret"
      }
    )
  }

  /* Extract datasets defined via dataform.json variables if any, it should include 3 variables for each dataset with next format:
      "dataset_id_<DATASET_IDENTIFIER>":"<YOUR_DATASET_NAME>",
      "dataset_projectid_<DATASET_IDENTIFIER>":"<YOUR_DATASET_PROJECT>",
      "dataset_location_<DATASET_IDENTIFIER>":"<YOUR_DATASET_LOCATION>",
  */
  dataform_configs = [
    for repo_key, repo_data in var.dataform_repositories :
    jsondecode(data.github_repository_file.dataform_config[repo_key].content)
  ]

  all_vars = merge([
    for config in local.dataform_configs : config.vars
  ]...)

  variables = ({
    for k, v in local.all_vars : split("_", k)[2] => {
      (split("_", k)[1]) = v
    }...
    if substr(k, 0, 8) == "dataset_"
  })

  dataform_datasets = {
    for dataset_name, attribute_list in local.variables : dataset_name => merge(attribute_list...)
  }

  all_created_datasets = merge(
    { for k, v in var.ddl_buckets :
      "${v.ddl_dataset_id}-${v.ddl_project_id}-${v.ddl_region}" => {
        dataset_id = v.ddl_dataset_id
        project    = v.ddl_project_id
        location   = v.ddl_region
        lake       = v.dataplex_lake
        zone       = v.dataplex_zone
        from_gcs   = true
        from_dataform = false
      } if v.ddl_flavor == "bigquery"
    },
    { for k, v in local.dataform_datasets :
      "${v.id}-${v.projectid}-${v.location}" => {
        dataset_id  = v.id
        project     = v.projectid
        location    = v.location
        description = v.description
        lake        = v.lake
        zone        = v.zone
        from_dataform = true
        from_gcs   = false
      }
    }
  )
}