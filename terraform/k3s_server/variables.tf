variable "region" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type    = string
  default = "task1"
}

variable "public_key_path" {
  type    = string
  default = "../data/task1.pub"
}

variable "cloudflare_api_token" {
  type = string
}

variable "cloudflare_zone_id" {
  type    = string
  default = "3f120390f275a40d8cd6133dadbb8b92"
}

variable "cloudflare_domain" {
  type    = string
  default = "bisus.net"
}

variable "github_action_token" {
  type = string
}