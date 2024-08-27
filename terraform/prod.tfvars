project = "<PROJECT_ID>"
region  = "us-central1"
domain  = "example"

include_metadata_in_tfe_deployment = true

create_dataform_repositories    = true
compile_dataform_repositories   = true
execute_dataform_repositories   = true
create_dataform_datasets        = true
dataform_repositories           = {
  sample-repo-1 = {
    remote_repo_url = "https://github.com/<GITHUB_SPACE>/aef-sample-dataform-repo.git"
  }
}

create_ddl_buckets  = false
run_ddls_in_buckets = true
ddl_buckets         = {
  ddl-bucket-1 = {
    ddl_flavor           = "bigquery"
    bucket_name          = "<PROJECT_ID>-my-sample-ddl-bucket"
    bucket_region        = "us-central1"
    bucket_project       = "<PROJECT_ID>"
    ddl_project_id       = "<PROJECT_ID>"
    ddl_dataset_id       = "aef_landing_sample_dataset"
    ddl_data_bucket_name = "<PROJECT_ID>-my-sample-data-bucket"
    ddl_connection_name  = "projects/<PROJECT_ID>/locations/us-central1/connections/sample-connection"
  }
}

create_data_buckets = false
data_buckets        = {
  data-bucket-1 = {
    name          = "<PROJECT_ID>-my-sample-data-bucket"
    region        = "us-central1"
    project       = "<PROJECT_ID>"
    dataplex_lake = "aef-sales-lake"
    dataplex_zone = "aef-landing-sample-zone"
    auto_discovery_of_tables = true
  }
}