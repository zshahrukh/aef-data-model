/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
provider "github" {
  token = var.git_token
  owner = "demo"
}

#project reference to get project number
data "google_project" "project" {
  project_id = var.project
}

# Create sample storage bucket.
resource "google_storage_bucket" "sample_data_bucket" {
  name                     = "${var.sample_data_bucket_project}-my-sample-data-bucket"
  location                 = var.sample_data_bucket_region
  project                  = var.sample_data_bucket_project
  public_access_prevention = "enforced"
  force_destroy            = true
}

# Create temp storage bucket.
resource "google_storage_bucket" "temp_data_bucket" {
  name                     = "${var.temp_data_bucket_project}-temp"
  location                 = var.temp_data_bucket_region
  project                  = var.temp_data_bucket_project
  public_access_prevention = "enforced"
  force_destroy            = true
}

resource "google_storage_bucket" "sample_ddl_bucket" {
  name                     = "${var.sample_ddl_bucket_project}-my-sample-ddl-bucket"
  location                 = var.sample_ddl_bucket_region
  project                  = var.sample_ddl_bucket_project
  public_access_prevention = "enforced"
  force_destroy            = true
}

# Copy data files to gcs
resource "google_storage_bucket_object" "data_files" {
  for_each   = var.sample_data_files
  name       = each.value.name
  source     = each.value.source
  bucket     = google_storage_bucket.sample_data_bucket.name
  depends_on = [google_storage_bucket.sample_data_bucket]
}

# Copy ddl files to gcs
resource "google_storage_bucket_object" "ddl_files" {
  for_each   = var.sample_ddl_files
  name       = each.value.name
  source     = each.value.source
  bucket     = google_storage_bucket.sample_ddl_bucket.name
  depends_on = [google_storage_bucket.sample_ddl_bucket]
}

# Creates a cloud resource connection.
resource "google_bigquery_connection" "connection" {
  #connection_id = local.connections["connection_name"]["connection"]
  connection_id = "sample-connection"
  project       = var.sample_connection_project
  location      = var.sample_connection_region
  cloud_resource {}
}

# Grants permissions to the service account of the connection created in the last step.
resource "google_project_iam_member" "connectionPermissionGrant" {
  project = var.sample_connection_project
  role    = "roles/storage.objectViewer"
  member  = format("serviceAccount:%s", google_bigquery_connection.connection.cloud_resource[0].service_account_id)
}

data "github_repository_file" "dataform_config" {
  for_each   = var.dataform_repositories
  repository = local.git_path[each.key]
  branch     = each.value.branch
  file       = "dataform.json"
}

module "fake_on_prem_instance" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/cloudsql-instance"
  project_id     = var.project
  network_config = {
    connectivity = {
      public_ipv4 = true
      psa_config  = {
        private_network = module.vpc.self_link
      }
    }
  }
  name                          = "fake-on-prem-instance"
  region                        = var.region
  database_version              = "POSTGRES_13"
  tier                          = "db-g1-small"
  gcp_deletion_protection       = "false"
  terraform_deletion_protection = "false"
  depends_on                    = [module.vpc]
}

module "vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc"
  project_id = var.project
  name       = "sample-vpc"
  psa_configs = [{
    ranges = { cloud-sql = "10.60.0.0/16" }
  }]
  subnets = [
    {
      name          = "default-${var.region}"
      region        = var.region
      ip_cidr_range = "10.0.0.0/24"
    }
  ]
}

module "firewall" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc-firewall"
  project_id = var.project
  network    = module.vpc.name
  default_rules_config = {
    disabled = true
  }
  ingress_rules = {
    allow-ingress-all = {
      description = "Allow subnet communication on all ports."
      source_ranges = ["10.0.0.0/24"]
      destination_ranges = ["10.0.0.0/24"]
      rules= [{ protocol = "all", ports = [] }]
    }
  }
}

resource "google_sql_user" "user" {
  project  = var.project
  name     = "user1"
  instance = module.fake_on_prem_instance.name
  password = "changeme"
}

resource "null_resource" "init_db" {
  provisioner "local-exec" {
    command = <<EOF
        curl -o cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.9.0/cloud-sql-proxy.darwin.arm64
        chmod +x cloud-sql-proxy
        nohup ./cloud-sql-proxy ${var.project}:${var.region}:${module.fake_on_prem_instance.name} >/dev/null & >/dev/null &
        sleep 3
        psql "host=127.0.0.1 sslmode=disable dbname=postgres user=user1 password=changeme" -f ../fake-on-prem-postgresql/sample_db_populator.sql
        PID=$(lsof -i tcp:5432 | grep LISTEN | awk '{print $2}')
        kill -9 $PID
      EOF
  }
  depends_on = [google_sql_user.user]
}

resource "null_resource" "cleanup" {
  triggers = {
    region      = var.region
    project = var.project
  }
  provisioner "local-exec" {
    when    = destroy
    command = <<EOF
      nohup ./cloud-sql-proxy ${self.triggers.project}:${self.triggers.region}:fake-on-prem-instance >/dev/null & >/dev/null &
      sleep 3
      psql "host=127.0.0.1 sslmode=disable dbname=postgres user=user1 password=changeme" -f ../fake-on-prem-postgresql/cleanup_db.sql
      gcloud compute networks peerings delete servicenetworking-googleapis-com --network=sample-vpc
      PID=$(lsof -i tcp:5432 | grep LISTEN | awk '{print $2}')
      kill -9 $PID
      rm cloud-sql-proxy
    EOF
  }
  depends_on = [module.vpc, google_sql_user.user]
}