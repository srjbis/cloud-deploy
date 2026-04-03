provider "google" {
    project = var.project_id
    region  = var.region
    zone    = var.zone
}

provider "kubernetes" {
    host                   = module.gke.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "helm" {
    kubernetes = {
        host                   = module.gke.endpoint
        token                  = data.google_client_config.default.access_token
        cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    }
}

data "google_client_config" "default" {}