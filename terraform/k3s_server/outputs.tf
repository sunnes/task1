output "k3s_server_ip" {
  value = aws_instance.k3s_server.public_ip
}

output "k3s_server_id" {
  value = aws_instance.k3s_server.id
}