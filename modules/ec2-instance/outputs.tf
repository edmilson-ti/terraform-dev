output "instance_id" {
  description = "O ID da instância criada."
  value       = aws_instance.server.id
}

output "instance_private_ip" {
  description = "O IP privado da instância."
  value       = aws_instance.server.private_ip
}

output "elastic_ip_address" {
  description = "O endereço do Elastic IP (se solicitado)."
  value       = try(one(aws_eip.eip[*].public_ip), "Nenhum IP Publico foi solicitado.")
}

output "iam_role_name" {
  description = "O nome da IAM Role criada."
  value       = aws_iam_role.ec2_role.name
}

output "instance_name" {
  description = "O nome (Tag Name) da instância criada"
  # Ajuste 'aws_instance.server' para o nome do recurso no seu módulo
  value       = aws_instance.server.tags["Name"]
}