resource "local_file" "service_account" {
  content = templatefile("${path.module}/templates/service_account.yaml.tpl", {
    namespace = var.namespace
    sa_name   = var.service_account_name
  })
  filename = "${path.module}/generated/service_account.yaml"
}

resource "local_file" "cluster_role_binding" {
  content = templatefile("${path.module}/templates/cluster_role_binding.yaml.tpl", {
    namespace = var.namespace,
    sa_name   = var.service_account_name
  })
  filename = "${path.module}/generated/cluster_role_binding.yaml"
}

resource "local_file" "deployment" {
  content = templatefile("${path.module}/templates/deployment.yaml.tpl", {
    namespace     = var.namespace,
    sa_name       = var.service_account_name,
    runner_name   = var.runner_name,
    github_url    = var.github_url,
    github_token  = var.github_action_token,
    runner_labels = var.runner_labels,
    runner_group  = var.runner_group
  })
  filename = "${path.module}/generated/deployment.yaml"
}

resource "null_resource" "apply_github_manifests" {
  connection {
    host        = var.remote_k3s_ip
    user        = "ubuntu"
    private_key = file("~/.ssh/task1")
    timeout     = "3m"
  }
  provisioner "local-exec" {
    command = <<EOT
        mkdir -p $GITHUB_WORKSPACE/.kube
        scp -i $HOME/.ssh/task1 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@${var.remote_k3s_ip}:/home/ubuntu/.kube/extconfig $GITHUB_WORKSPACE/.kube/config
      EOT
  }
  provisioner "local-exec" {
    command = <<EOT
      kubectl --kubeconfig=$GITHUB_WORKSPACE/.kube/config create namespace ${var.namespace}
      kubectl --kubeconfig=$GITHUB_WORKSPACE/.kube/config  apply -f ${path.module}/generated/service_account.yaml
      kubectl --kubeconfig=$GITHUB_WORKSPACE/.kube/config  apply -f ${path.module}/generated/cluster_role_binding.yaml
      kubectl --kubeconfig=$GITHUB_WORKSPACE/.kube/config  apply -f ${path.module}/generated/deployment.yaml
    EOT
  }
}
