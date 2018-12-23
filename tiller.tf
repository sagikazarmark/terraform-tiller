variable "tiller_namespace" {
  type        = "string"
  default     = "kube-system"
  description = "The Kubernetes namespace to use to deploy Tiller."
}

variable "tiller_service_account" {
  type        = "string"
  default     = "tiller"
  description = "The Kubernetes service account to add to Tiller."
}

variable "tiller_replicas" {
  default     = 1
  description = "The amount of Tiller instances to run on the cluster."
}

variable "tiller_image" {
  type        = "string"
  default     = "gcr.io/kubernetes-helm/tiller"
  description = "The image used to install Tiller."
}

variable "tiller_version" {
  type        = "string"
  default     = "v2.11.0"
  description = "The Tiller image version to install."
}

variable "tiller_max_history" {
  default     = 0
  description = "Limit the maximum number of revisions saved per release. Use 0 for no limit."
}

variable "tiller_net_host" {
  type        = "string"
  default     = ""
  description = "Install Tiller with net=host."
}

variable "tiller_node_selector" {
  type        = "map"
  default     = {}
  description = "Determine which nodes Tiller can land on."
}

# See https://github.com/helm/helm/blob/master/cmd/helm/installer/install.go#L199
resource "kubernetes_deployment" "tiller" {
  count = "${var.rbac_enabled ? 0 : 1}"

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
        }

        host_network  = "${var.tiller_net_host}"
        node_selector = "${var.tiller_node_selector}"
      }
    }
  }
}
