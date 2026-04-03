terraform {
  backend "gcs" {
    bucket  = "srjbis007-terraform-state-bucket"
    prefix  = "gke/state"
  }
}
