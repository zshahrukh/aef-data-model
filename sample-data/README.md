## Demo Appendix
Use this in case you want to create some sample data sources (GCS bucket with some files, and a Cloud SQL Postgres DB with 1 populated table), this will:
  - Create a BigLake connection for GCS files.
  - Create data landing GCS buckets. And uploads sample data.
  - Create a dummy PostgreSQL database to simulate an on-premises data source that can't be accessed using BigQuery Omni or BigLake. And inserts sample data.

### Usage
**Important:** Using this repository involves creating tables and managing data. We've included simple data and tables for demonstration.

#### Steps
1. **Terraform:** Define your terraform variables. You could create a `.tfvars` file like this:
    ```hcl
    project             = "my-project"
    region              = "us-central1"
    sample_data_bucket  = "my-sample-data-bucket"
    sample_default_date = "2024-02-26"
    
    git_token             = "my-git-token-value"
    dataform_repositories = {
      sample-repo-1 = {
        remote_repo_url      = "https://github.com/my-dataform-repo.git"
        secret_name          = "my-github-token-secret-1"
        service_account_name = "aef-dataform-repo1-sa"
      }
    }
    sample_files = {
      "location" = {
        name   = "locations/location.csv"
        source = "../gcs-files/location.csv"
      },
      ...
    }
    sample_connection_project = "analytics-engg-framework-demo"
    sample_connection_region = "us-central1"
    ```
<!-- BEGIN TFDTFOC -->
## Variables

| name                                         | description                                                                                                                           | type | required | default |
|----------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|---|---|---|
| [project](variables.tf#L17)                  | Project where the core BigLake bigquery_connection and other resources will be created.                                               | string | true | - | 
| [region](variables.tf#L23)                   | Region where the core BigLake bigquery_connection and other resources will be created.                                                | string | true | - |
| [dataform_repositories](variables.tf#L29)    | Dataform repository remote settings required to attach the repository to a remote repository.                                         | map(object({ <br>  remote_repo_url = optional(string), <br>  branch = optional(string, "main"), <br>  secret_name = optional(string), <br>  secret_version = optional(string, "v1"), <br>  service_account_name = optional(string) <br> })) | false | {} |
| [git_token](variables.tf#L40)                | Git token to access the dataform repositories, it will be used to connect and read the dataform.json to create the BigLake connection | string | true | - |
| [sample_data_files](variables.tf#L61)        | A map where values are objects containing 'source' (path to the file)                                                                 | map(object({ <br>  name = string, <br>  source = string <br> }))  | false | null |
| [sample_ddl_bucket_project](variables.tf#L70) | A project where a sample ddl bucket will be created.                                                                                        | string | false | null |
| [sample_ddl_bucket_region](variables.tf#L75) | A region where a sample ddl bucket will be created.                                                                                        | string | false | null |
| [sample_ddl_files](variables.tf#L80)         | A map where values are objects containing 'source' (path to the file)                                                                 | map(object({ <br>  name = string, <br>  source = string <br> }))  | false | null |
| [sample_connection_project](variables.tf#L89) | A project where a sample connection will be created. (Could be referenced in Dataform repositories).                                 | string | false | null |
| [sample_connection_region](variables.tf#L94)  | A region where a sample connection will be created. (Could be referenced in Dataform repositories)                                 | string | false | null |
| [sample_data_bucket_project](variables.tf#L100) | A project where a sample data bucket will be created.                                                                                        | string | false | null |
| [sample_data_bucket_region](variables.tf#L105) | A region where a sample data bucket will be created.                                                                                        | string | false | null |
| [temp_data_bucket_project](variables.tf#L111) | A project where a sample temp bucket will be created.                                                                                        | string | false | null |
| [temp_data_bucket_region](variables.tf#L116) | A region where a sample temp bucket will be created.                                                                                        | string | false | null |
<!-- END TFDOC -->
1. Run the Terraformn Plan / Apply
```commandline
terraform plan -var-file="demo.tfvars"
```

1. Cleaning
```commandline
terraform destroy -var-file="demo.tfvars"
```
