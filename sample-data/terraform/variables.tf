/**
 * Copyright 2025 Google LLC
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

variable "project" {
  description = "Project where the core BigLake bigquery_connection and other resources will be created."
  type        = string
  nullable    = false
}

variable "region" {
  description = "Region where the core BigLake bigquery_connection and other resources will be created."
  type        = string
  nullable    = false
}

variable "dataform_repositories" {
  description = "Dataform repository remote settings required to attach the repository to a remote repository."
  type        = map(object({
    remote_repo_url      = optional(string)
    branch               = optional(string, "main")
    secret_name          = optional(string)
    secret_version       = optional(string, "v1")
  }))
  default = {}
}

variable "git_token" {
  description = "Git token to access the dataform repositories, it will be used to connect and read the dataform.json to create the BigLake connection"
  type        = string
  nullable    = false
  sensitive   = true
}

variable "sample_data_files" {
  nullable = true
  default  = null
  type     = map(object({
    name   = string
    source = string
  }))
  description = "A map where values are objects containing 'source' (path to the file)"
}

variable "sample_ddl_bucket_project" {
  nullable = true
  type     = string
  description = "A region where a sample ddl bucket will be created."
}

variable "sample_ddl_bucket_region" {
  nullable = true
  type     = string
  description = "A region where a sample ddl bucket will be created."
}

variable "sample_ddl_files" {
  nullable = true
  default  = null
  type     = map(object({
    name   = string
    source = string
  }))
  description = "A map where values are objects containing 'source' (path to the file)"
}

variable "sample_connection_project" {
  nullable = true
  type     = string
  description = "A project where a sample connection will be created. (Could be referenced in Dataform repositories)."
}

variable "sample_connection_region" {
  nullable = true
  type     = string
  description = "A region where a sample connection will be created. (Could be referenced in Dataform repositories)"
}

variable "sample_data_bucket_project" {
  nullable = true
  type     = string
  description = "A project where a sample data bucket will be created."
}

variable "sample_data_bucket_region" {
  nullable = true
  type     = string
  description = "A region where a sample data bucket will be created."
}

variable "temp_data_bucket_project" {
  nullable = true
  type     = string
  description = "A project where a sample temp bucket will be created."
}

variable "temp_data_bucket_region" {
  nullable = true
  type     = string
  description = "A region where a sample temp bucket will be created."
}
