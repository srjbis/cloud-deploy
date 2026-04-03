resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  create_namespace = false

  values = [
    <<EOF
server:
  service:
    type: LoadBalancer
EOF
  ]
}

resource "kubernetes_manifest" "argocd_app" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"

    metadata = {
      name      = "root-app"
      namespace = "argocd"
    }

    spec = {
      source = {
        repoURL        = "https://github.com/srjbis/cloud-deploy.git"
        path           = "apps/"
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

  depends_on = [helm_release.argocd]
}