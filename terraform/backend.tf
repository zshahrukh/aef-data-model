terraform {
  backend "gcs" {
    bucket = "aef-shahcago-hackathon-tfe"
    prefix = "aef-data-model/environments/dev"
  }
}