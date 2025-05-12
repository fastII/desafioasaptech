# Outputs for public ip

output "public_ip" {
  value = aws_instance.minikube.public_ip
}