variable "kubeconfig" {
  type = string
}

variable "github_repo_url" {
  type = string
}

variable "github_action_token" {
  type = string
}

variable "replicas" {
  type    = number
  default = 1
}