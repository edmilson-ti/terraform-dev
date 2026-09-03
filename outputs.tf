output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "Bloco CIDR da VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Lista dos IDs das subnets públicas"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Lista dos IDs das subnets privadas"
  value       = module.vpc.private_subnets
}
