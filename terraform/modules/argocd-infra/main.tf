resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "9.4.16"

  create_namespace = false

  values = [
    <<EOF
server:
  service:
    type: LoadBalancer
EOF
  ]

  wait    = true
  timeout = 600
  depends_on = [ kubernetes_namespace_v1.argocd ]
}
