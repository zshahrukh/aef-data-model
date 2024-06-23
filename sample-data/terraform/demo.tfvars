project             = "analytics-engg-framework-demo"
region              = "us-central1"
sample_default_date = "2024-02-26"

git_token             = "***REMOVED***"
dataform_repositories = {
  sample-repo-1 = {
    remote_repo_url      = "https://github.com/oscarpulido55/aef-sample-dataform-repo.git"
  }
}

sample_data_bucket  = "analytics-engg-framework-demo-my-sample-data-bucket"
temp_data_bucket = "aef-analytics-engg-framework-demo-temp"
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

sample_ddl_bucket  = "analytics-engg-framework-demo-my-sample-ddl-bucket"
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