project = "analytics-engg-framework-demo"
region  = "us-central1"
domain  = "google"

include_metadata_in_tfe_deployment = true

create_dataform_repositories    = true
compile_dataform_repositories   = true
execute_dataform_repositories   = true
create_dataform_datasets        = true
dataform_repositories_git_token = "YOUR_GIT_TOKEN"
dataform_repositories           = {
  sample-repo-1 = {
    remote_repo_url = "https://github.com/oscarpulido55/aef-sample-dataform-repo.git"
  }
}

create_data_buckets = false
data_buckets        = {
  data-bucket-1 = {
    name          = "analytics-engg-framework-demo-my-sample-data-bucket"
    region        = "us-central1"
    project       = "analytics-engg-framework-demo"
    dataplex_lake = "aef-sales-lake"
    dataplex_zone = "aef-landing-sample-zone"
    auto_discovery_of_tables = true
  }
}

create_ddl_buckets  = false
run_ddls_in_buckets = true
ddl_buckets         = {
  ddl-bucket-1 = {
    bucket_name          = "analytics-engg-framework-demo-my-sample-ddl-bucket"
    bucket_region        = "us-central1"
    bucket_project       = "analytics-engg-framework-demo"
    ddl_flavor           = "bigquery"
    ddl_project_id       = "analytics-engg-framework-demo"
    ddl_dataset_id       = "aef_landing_sample_dataset"
    ddl_data_bucket_name = "analytics-engg-framework-demo-my-sample-data-bucket"
    ddl_connection_name  = "projects/analytics-engg-framework-demo/locations/us-central1/connections/sample-connection"
  }
}