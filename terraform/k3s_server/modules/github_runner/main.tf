provider "kubernetes" {
  config_path = var.kubeconfig
}

resource "kubernetes_namespace" "github_runners" {
  metadata {
    name = "github-runners"
  }
}

resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "github-token"
    namespace = kubernetes_namespace.github_runners.metadata[0].name
  }

  data = {
    token = var.github_action_token
  }
}

resource "kubernetes_deployment" "github_action_runner" {
  metadata {
    name      = "github-action-runner"
    namespace = kubernetes_namespace.github_runners.metadata[0].name
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = "github-action-runner"
      }
    }

    template {
      metadata {
        labels = {
          app = "github-action-runner"
        }
      }

      spec {
        container {
          name  = "runner"
          image = "myoung34/github-runner:latest"

          env {
            name  = "REPO_URL"
            value = var.github_repo_url
          }

          env {
            name = "RUNNER_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.github_token.metadata[0].name
                key  = "token"
              }
            }
          }

          env {
            name  = "RUNNER_NAME"
            value = "self-hosted-runner-0"
          }

          env {
            name  = "RUNNER_WORKDIR"
            value = "/tmp/github-runner"
          }

          volume_mount {
            mount_path = "/tmp/github-runner"
            name       = "workdir"
          }
        }

        volume {
          name = "workdir"
          empty_dir {}
        }
      }
    }
  }
}