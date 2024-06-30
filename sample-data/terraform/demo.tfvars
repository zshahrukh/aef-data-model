project             = "analytics-engg-framework-demo"
region              = "us-central1"

git_token             = "YOUR_GIT_TOKEN"
dataform_repositories = {
  sample-repo-1 = {
    remote_repo_url      = "https://github.com/oscarpulido55/aef-sample-dataform-repo.git"
  }
}

sample_connection_project = "analytics-engg-framework-demo"
sample_connection_region = "us-central1"

sample_data_bucket_project = "analytics-engg-framework-demo"
sample_data_bucket_region = "us-central1"
sample_data_files = {
  "location" = {
    name   = "locations/location.csv"
    source = "../gcs-files/location.csv"
  },
  "product" = {
    name   = "products/product.csv"
    source = "../gcs-files/product.csv"
  },
  "sales-dt1" = {
    name   = "sales/dt=2024-03-11/sales_dt1.csv"
    source = "../gcs-files/sales_dt1.csv"
  },
  "sales-dt2" = {
    name   = "sales/dt=2024-03-12/sales_dt2.csv"
    source = "../gcs-files/sales_dt2.csv"
  }
}

temp_data_bucket_region = "us-central1"
temp_data_bucket_project = "analytics-engg-framework-demo"

sample_ddl_bucket_project  = "analytics-engg-framework-demo"
sample_ddl_bucket_region = "us-central1"
sample_ddl_files = {
  "sales" = {
    name   = "raw_sales.sql"
    source = "../gcs-files/raw_sales.sql"
  },
  "suppliers" = {
    name   = "raw_suppliers.sql"
    source = "../gcs-files/raw_suppliers.sql"
  }
}