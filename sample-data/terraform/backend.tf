terraform {
  backend "gcs" {
    bucket = "aef-shahcago-hackathon-tfe"
    prefix = "sample-data/environments/dev"
  }
}