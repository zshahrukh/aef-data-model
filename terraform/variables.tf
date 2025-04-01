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
variable "include_metadata_in_tfe_deployment" {
  description = "Controls whether metadata is deployed alongside Terraform resources. If false Metadata can be deployed as a next step in a CICD pipeline."
  type        = bool
  nullable    = false
}

variable "overwrite_metadata" {
  description = "Whether to overwrite existing Dataplex (Cortex Datamesh) metadata."
  type        = string
  nullable    = false
  default     = false
}

variable "create_dataform_datasets" {
  description = "Controls whether the datasets found in the dataform.json files in the repositories will be created alongside Terraform resources. If false datasets should be created otherwise."
  type        = bool
  nullable    = false
}

variable "create_ddl_buckets_datasets" {
  description = "Controls whether the datasets referenced in the GCS DDL buckets will be created alongside Terraform resources. If false datasets should be created otherwise."
  type        = bool
  nullable    = false
}

variable "create_dataform_repositories" {
  description = "Controls whether the dataform scripts found in the repositories will be created alongside Terraform resources. If false dataform repositories should be created as an additional step in the CICD pipeline."
  type        = bool
  nullable    = false
}

variable "compile_dataform_repositories" {
  description = "Controls whether the dataform scripts found in the repositories will be compiled alongside Terraform resources. If false dataform repositories should be compiled as an additional step in the CICD pipeline."
  type        = bool
  nullable    = false
}

variable "execute_dataform_repositories" {
  description = "Controls whether the dataform scripts found in the repositories will be executed alongside Terraform resources. If false dataform repositories should be executed as an additional step in the CICD pipeline."
  type        = bool
  nullable    = false
}

variable "domain" {
  description = "Your organization or domain name, organization if centralized data management, domain name if one repository for each data domain in a Data mesh environment."
  type        = string
  nullable    = false
}

variable "project" {
  description = "Project where the the dataform repositories, the Dataplex metadata, and other resources will be created."
  type        = string
  nullable    = false
}

variable "region" {
  description = "Region where the datasets from the dataform.json files, the dataform repositories, the Dataplex metadata, and other resources will be created."
  type        = string
  nullable    = false
}

variable "dataform_repositories" {
  description = "Dataform repository remote settings required to attach the repository to a remote repository."
  type        = map(object({
    remote_repo_url = optional(string)
    branch          = optional(string, "main")
    secret_version  = optional(string, "v1")
  }))
  default = {}
}

variable "dataform_repositories_git_token" {
  description = "Git token to access the dataform repositories, it will be stored as a secret in secret manager, and it will be used to connect and read the dataform.json to create the datasets."
  type        = string
  nullable    = false
  sensitive   = true
}

variable "create_data_buckets" {
  description = "Controls whether the referenced data buckets will be created. If false referenced buckets should exist."
  type        = bool
  nullable    = false
}

variable "data_buckets" {
  description = "Data buckets."
  type        = map(object({
    name                     = optional(string)
    region                   = optional(string)
    project                  = optional(string)
    dataplex_lake            = optional(string)
    dataplex_zone            = optional(string)
    auto_discovery_of_tables = optional(string)
  }))
  default = {}
}

variable "create_ddl_buckets" {
  description = "Controls whether the referenced buckets containing DDLs will be created. If false referenced buckets should exist."
  type        = bool
  nullable    = false
}

variable "run_ddls_in_buckets" {
  description = "Controls whether the .sql files in the referenced DDL buckets should be run."
  type        = bool
  nullable    = false
}

variable "ddl_buckets" {
  description = "Buckets containing .sql DDL scripts to be executed on Terraform deploy, It can be of flavors: bigquery, TODO "
  type        = map(object({
    bucket_name          = optional(string)
    bucket_region        = optional(string)
    bucket_project       = optional(string)
    ddl_flavor           = optional(string)
    ddl_project_id       = optional(string)
    ddl_dataset_id       = optional(string)
    ddl_region           = optional(string)
    ddl_data_bucket_name = optional(string)
    ddl_connection_name  = optional(string)
    dataplex_lake        = optional(string)
    dataplex_zone        = optional(string)
  }))
  default = {}
}