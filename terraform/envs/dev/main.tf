module "gke" {
  source       = "../../modules/gke"
  project_id   = var.project_id
  region       = var.region
  zone         = var.zone
  instance_type = var.instance_type
  cluster_name = "prod-gke"
}

module "argocd" {
  source = "../../modules/argocd"

  depends_on = [module.gke]
}
