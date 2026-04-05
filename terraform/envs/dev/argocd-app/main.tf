module "argocd-app" {
  source = "../../modules/argocd-app"

  depends_on = [module.argocd-infra]
}