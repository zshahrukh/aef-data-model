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
    ```
<!-- BEGIN TFDTFOC -->
## Variables

| name                                      | description                                                                                                                           | type | required | default |
|-------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|---|---|---|
| [project](variables.tf#L17)               | Project where the core BigLake bigquery_connection and other resources will be created.                                               | string | true | - | 
| [region](variables.tf#L23)                | Region where the core BigLake bigquery_connection and other resources will be created.                                                | string | true | - |
| [dataform_repositories](variables.tf#L29) | Dataform repository remote settings required to attach the repository to a remote repository.                                         | map(object({ <br> &emsp;remote_repo_url = optional(string), <br> &emsp;branch = optional(string, "main"), <br> &emsp;secret_name = optional(string), <br> &emsp;secret_version = optional(string, "v1"), <br> &emsp;service_account_name = optional(string) <br> })) | false | {} |
| [git_token](variables.tf#L41)             | Git token to access the dataform repositories, it will be used to connect and read the dataform.json to create the BigLake connection | string | true | - |
| [sample_data_bucket](variables.tf#L48)    | Bucket where sample data will be stored.                                                                                              | string | false | null |
| [sample_files](variables.tf#L55)          | A map where values are objects containing 'source' (path to the file) and optional 'content'.                                         | map(object({ <br> &emsp;name = string, <br> &emsp;source = string <br> }))  | false | null |
| [sample_default_date](variables.tf#L65)   | A default processing date, that will be used as filter for data ingestions.                                                           | string | false | null |
<!-- END TFDOC -->



1. Run the Terraformn Plan / Apply
```commandline
terraform plan -var-file="demo.tfvars"
```

1. Cleaning
```commandline
terraform destroy -var-file="demo.tfvars"
```
