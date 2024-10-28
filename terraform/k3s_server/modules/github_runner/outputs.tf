output "github_runner_deployment_name" {
  value = kubernetes_deployment.github_action_runner.metadata[0].name
}
