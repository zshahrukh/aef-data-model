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

# Create cortex temporal storage bucket, to store tmp files generated during deployment.
resource "google_storage_bucket" "tmp_cortex_bucket" {
  name                     = "${var.project}-cortex-tmp-bucket"
  location                 = var.region
  project                  = var.project
  public_access_prevention = "enforced"
  force_destroy            = true
}

#Runs the cortex datamesh deployer with the given parameters in the defined folder structure.
resource "null_resource" "run_metadata_deployer" {
  count = var.include_metadata_in_tfe_deployment ? 1 : 0
  provisioner "local-exec" {
    command = <<EOF
      python3 -m venv aef_metadata_deployer
      source aef_metadata_deployer/bin/activate
      python3 ../cicd-deployers/metadata_deployer.py --project_id ${var.project} --location ${var.region} --overwrite ${var.overwrite_metadata}
    EOF
  }
  triggers = {
    always_run = timestamp()
  }
  depends_on = [google_storage_bucket.data_buckets]
}
# TODO move to Cortex Datamesh (once cortex datamesh supports setting discovery)
#Create BigQuery dataset Assets in Dataplex, with auto discovery so tables will be discovered and added as entities
resource "google_dataplex_asset" "dataset_assets" {
  for_each      = var.include_metadata_in_tfe_deployment ? local.all_created_datasets : {}
  project       = var.project
  name          = replace(each.value.dataset_id, "_", "-")
  location      = each.value.location
  lake          = each.value.lake
  dataplex_zone = each.value.zone
  discovery_spec {
    enabled = true
  }
  resource_spec {
    name = "projects/${each.value.project}/datasets/${each.value.dataset_id}"
    type = "BIGQUERY_DATASET"
  }
  labels = {
    domain      = var.domain
  }
  depends_on = [null_resource.run_metadata_deployer]
}

#TODO move to Cortex Datamesh (once cortex datamesh supports setting discovery)
#Create GCS buckets Assets in Dataplex
resource "google_dataplex_asset" "gcs_assets" {
  for_each      = var.data_buckets
  project       = var.project
  name          = each.value.name
  location      = var.region
  lake          = each.value.dataplex_lake
  dataplex_zone = each.value.dataplex_zone
  discovery_spec {
    enabled = each.value.auto_discovery_of_tables
  }
  resource_spec {
    name = "projects/${each.value.project}/buckets/${each.value.name}"
    type = "STORAGE_BUCKET"
  }
  labels = {
    domain      = var.domain
  }
  depends_on = [null_resource.run_metadata_deployer]
}