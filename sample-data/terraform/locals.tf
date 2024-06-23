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

  #Reads dataform.json files
  dataform_configs = [
    for repo_key, repo_data in var.dataform_repositories :
    jsondecode(data.github_repository_file.dataform_config[repo_key].content)
  ]
  all_vars = merge([
    for config in local.dataform_configs : config.vars
  ]...)

  /* Create BigLake Connection Name:
      "connection_name_YOUR_CONNECTION_NAME"
  */
  variables = ({
    for k, v in local.all_vars : k => {
      connection = v
    }...
    if k == "connection_name"
  })

  connections = {
    for dataset_name, attribute_list in local.variables : dataset_name => merge(attribute_list...)
  }
}