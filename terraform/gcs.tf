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

# Create data storage buckets.
resource "google_storage_bucket" "data_buckets" {
  for_each    = var.create_data_buckets ? var.data_buckets : {}
  name                     = each.value.name
  location                 = each.value.region
  project                  = each.value.project
  public_access_prevention = "enforced"
  force_destroy            = false
  uniform_bucket_level_access = true
}

# Create buckets containing DDLs.
resource "google_storage_bucket" "ddl_buckets" {
  for_each    = var.create_ddl_buckets ? var.ddl_buckets : {}
  name                     = each.value.bucket_name
  location                 = each.value.bucket_region
  project                  = each.value.bucket_project
  public_access_prevention = "enforced"
  force_destroy            = false
  uniform_bucket_level_access = true
}

resource "google_bigquery_dataset" "gcs_datasets" {
  for_each    = var.create_ddl_buckets_datasets ? { for k, v in local.all_created_datasets : k => v if v.from_gcs } : {}
  dataset_id  = each.value.dataset_id
  project     = each.value.project
  location    = each.value.location
}
