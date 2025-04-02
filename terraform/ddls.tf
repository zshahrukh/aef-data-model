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

#Run the BigQuery ddls found in the ddl buckets
resource "null_resource" "run_ddls" {
  for_each = var.run_ddls_in_buckets ? var.ddl_buckets : {}
  provisioner "local-exec" {
    command = <<EOF
      python3 -m venv aef_bigquery_ddl_runner
      source aef_bigquery_ddl_runner/bin/activate
      pip install google-api-core
      pip install google-cloud-bigquery
      pip install google-cloud-storage
      python3 ../cicd-deployers/bigquery_ddl_runner.py --project_id ${each.value.bucket_project} --location ${each.value.bucket_region} --bucket ${each.value.bucket_name} --ddl_project_id ${each.value.ddl_project_id} --ddl_dataset_id ${each.value.ddl_dataset_id} --ddl_data_bucket_name ${each.value.ddl_data_bucket_name} --ddl_connection_name ${each.value.ddl_connection_name}
    EOF
  }
  triggers   = {
    always_run = timestamp()
  }
  depends_on = [null_resource.run_metadata_deployer]
}