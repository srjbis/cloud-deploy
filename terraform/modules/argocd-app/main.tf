resource "kubernetes_manifest" "argocd-app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "root-app"
      namespace = "argocd"
    }

    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/srjbis/cloud-deploy.git"
        path           = "helm/argocd-apps"
        targetRevision = "HEAD"
      }

      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "default"
      }

      syncPolicy = {
        automated = {
            prune    = true
            selfHeal = true
        }
      }
    }
  }
}