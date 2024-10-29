variable "namespace" {
  type    = string
  default = "github-runner"
}

variable "service_account_name" {
  type    = string
  default = "github-runner-sa"
}

variable "runner_name" {
  type    = string
  default = "github-runner"
}

variable "github_url" {
  type = string
}

variable "github_action_token" {
  type      = string
  sensitive = true
}

variable "runner_labels" {
  type    = string
  default = "self-hosted,k8s"
}

variable "runner_group" {
  type    = string
  default = "Default"
}

variable "remote_k3s_ip" {
  type = string
}