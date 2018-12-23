# See https://github.com/helm/helm/blob/master/docs/rbac.md

variable "rbac_enabled" {
  default     = false
  description = "Whether to create role-based access control resources (service account and cluster role binding)."
}

resource "kubernetes_service_account" "tiller" {
  count = "${var.rbac_enabled}"

  metadata {
    name      = "tiller"
    namespace = "${var.tiller_namespace}"
  }
}

resource "kubernetes_cluster_role_binding" "tiller" {
  count = "${var.rbac_enabled}"

  metadata {
    name = "${var.tiller_service_account}"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "${kubernetes_service_account.tiller.metadata.0.name}"
    namespace = "${var.tiller_namespace}"

    # See https://github.com/terraform-providers/terraform-provider-kubernetes/issues/204
    api_group = ""
  }
}

# See https://github.com/helm/helm/blob/master/cmd/helm/installer/install.go#L199
# See https://github.com/terraform-providers/terraform-provider-kubernetes/issues/38#issuecomment-318581203
resource "kubernetes_deployment" "tiller_with_rbac" {
  count = "${var.rbac_enabled ? 1 : 0}"

  metadata {
    name      = "tiller-deploy"
    namespace = "${var.tiller_namespace}"

    labels {
      app  = "helm"
      name = "tiller"
    }
  }

  spec {
    replicas = "${var.tiller_replicas}"

    selector {
      match_labels {
        app  = "helm"
        name = "tiller"
      }
    }

    template {
      metadata {
        labels {
          app  = "helm"
          name = "tiller"
        }
      }

      spec {
        service_account_name = "${kubernetes_service_account.tiller.metadata.0.name}"

        container {
          name              = "tiller"
          image             = "${var.tiller_image}:${var.tiller_version}"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "tiller"
            container_port = 44134
          }

          port {
            name           = "http"
            container_port = 44135
          }

          env {
            name  = "TILLER_NAMESPACE"
            value = "${var.tiller_namespace}"
          }

          env {
            name  = "TILLER_HISTORY_MAX"
            value = "${var.tiller_max_history}"
          }

          liveness_probe {
            http_get {
              path = "/liveness"
              port = 44135
            }

            initial_delay_seconds = 1
            timeout_seconds       = 1
          }

          readiness_probe {
            http_get {
              path = "/readiness"
              port = 44135
            }

            initial_delay_seconds = 1
            timeout_seconds       = 1
          }

          # See https://github.com/terraform-providers/terraform-provider-kubernetes/issues/38#issuecomment-318581203
          volume_mount {
            mount_path = "/var/run/secrets/kubernetes.io/serviceaccount"
            name       = "${kubernetes_service_account.tiller.default_secret_name}"
            read_only  = true
          }
        }

        host_network  = "${var.tiller_net_host}"
        node_selector = "${var.tiller_node_selector}"

        # See https://github.com/terraform-providers/terraform-provider-kubernetes/issues/38#issuecomment-318581203
        volume {
          name = "${kubernetes_service_account.tiller.default_secret_name}"

          secret {
            secret_name = "${kubernetes_service_account.tiller.default_secret_name}"
          }
        }
      }
    }
  }
}
