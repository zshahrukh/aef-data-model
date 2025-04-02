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

output "dataform_repository_name" {
  value = local.repo_name
}

output "git_path" {
  value = local.git_path
}

output "dataform_config_all_vars_from_all_repos" {
  value = local.all_vars
}

output "dataform_datasets" {
  value = local.dataform_datasets
}

output "all_created_datasets" {
  value = local.all_created_datasets
}