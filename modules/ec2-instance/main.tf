# Criação da Role IAM
resource "aws_iam_role" "ec2_role" {
  name = "role-ssm-${var.instance_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Anexar a Política Gerenciada pela AWS para SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Criar o Instance Profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "profile-ssm-${var.instance_name}"
  role = aws_iam_role.ec2_role.name
}

# Tag Name com as tags personalizadas
locals {
  common_tags = merge(
    {
      "Name" = var.instance_name
    },
    var.custom_tags
  )
}

# LÓGICA PARA CRIAÇÃO DA KEY PAIR
# Só gera a chave RSA se NÃO houver uma chave existente informada
resource "tls_private_key" "rsa_key" {
  count     = var.key_name_aws == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Só registra a chave na AWS se o Terraform for o responsável por gerá-la
resource "aws_key_pair" "generated_key" {
  count      = var.key_name_aws == "" ? 1 : 0
  key_name   = "kpr-${var.instance_name}"
  public_key = tls_private_key.rsa_key[0].public_key_openssh
}

# Só cria o arquivo .pem local se uma nova chave for gerada
resource "local_file" "private_key_pem" {
  count           = var.key_name_aws == "" ? 1 : 0
  content         = tls_private_key.rsa_key[0].private_key_pem
  filename        = "${var.private_key_save_path}/kpr-${var.instance_name}.pem"
  file_permission = "0400"
}

# Cria o Security Group
resource "aws_security_group" "ec2_sg" {
  count = var.create_security_group ? 1 : 0
  
  name        = "secgrp-${var.instance_name}"
  description = "Security Group para a instancia ${var.instance_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "secgrp-${var.instance_name}"
    ManagedBy = "Terraform"
  }
}

# Recurso compacto para processar o mapa da raiz
resource "aws_security_group_rule" "extra" {
  for_each          = var.create_security_group ? var.extra_ingress : {}
  type              = "ingress"
  security_group_id = one(aws_security_group.ec2_sg[*].id)
  protocol          = "tcp"

  from_port   = each.key
  to_port     = each.key
  cidr_blocks = each.value
}

# Cria a instância EC2
resource "aws_instance" "server" {
  ami           = var.ami_id
  instance_type = var.instance_type 
  # Se estiver vazia, usa a chave gerada pelo Terraform [0].
  key_name      = var.key_name_aws != "" ? var.key_name_aws : aws_key_pair.generated_key[0].key_name
  
  subnet_id              = var.subnet_id 
  vpc_security_group_ids = var.create_security_group ? concat([aws_security_group.ec2_sg[0].id], var.additional_security_group_ids) : var.additional_security_group_ids
  
  associate_public_ip_address = var.assign_public_ip 
  iam_instance_profile        = var.iam_instance_profile_name != "" ? var.iam_instance_profile_name : aws_iam_instance_profile.ec2_profile.name
  user_data                   = var.user_data_script

  root_block_device {
    volume_size           = var.os_disk_size_gb
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
    tags = merge( 
      { Name = "${var.instance_name}-C" },
      var.custom_tags
    )
  }
  
  tags = merge(local.common_tags, var.tag_backup)
}

# --- LÓGICA DO IP PÚBLICO OPCIONAL ---
resource "aws_eip" "eip" {
  count  = var.assign_public_ip ? 1 : 0
  domain = "vpc"
  tags   = local.common_tags 
}

resource "aws_eip_association" "eip_assoc" {
  count         = var.assign_public_ip ? 1 : 0
  instance_id   = aws_instance.server.id
  allocation_id = aws_eip.eip[0].id
}

# --- LÓGICA DO DISCO DE DADOS OPCIONAL (LEGADO) ---
resource "aws_ebs_volume" "data_disk" {
  count = var.data_disk_size_gb > 0 ? 1 : 0

  availability_zone = aws_instance.server.availability_zone
  size              = var.data_disk_size_gb
  type              = "gp3"
  encrypted         = true
  tags = merge(
    { Name = "${var.instance_name}-D" },
    var.custom_tags
  )
}

resource "aws_volume_attachment" "data_disk_attach" {
  count = var.data_disk_size_gb > 0 ? 1 : 0

  device_name = "xvdh"
  volume_id   = aws_ebs_volume.data_disk[0].id
  instance_id = aws_instance.server.id
}

# --- NOVA LÓGICA DE MÚLTIPLOS DISCOS EXTRAS ---
resource "aws_ebs_volume" "extra_volumes" {
  for_each = var.ebs_volumes

  availability_zone = aws_instance.server.availability_zone
  size              = each.value.size
  type              = each.value.type
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id
  
  # Performance
  iops       = each.value.iops
  throughput = each.value.throughput

  tags = merge(
    var.custom_tags,
    each.value.tags,
    {
      Name = coalesce(
        each.value.name,
        "${var.instance_name}-${each.key}"
      )
    }
  )

  lifecycle {
    ignore_changes = [availability_zone]
  }
}

resource "aws_volume_attachment" "extra_volumes" {
  for_each = var.ebs_volumes

  device_name                    = each.value.device_name
  volume_id                      = aws_ebs_volume.extra_volumes[each.key].id
  instance_id                    = aws_instance.server.id
  stop_instance_before_detaching = false
}

# Aplica apenas as duas tags desejadas na ENI de forma compacta
resource "aws_ec2_tag" "eni_tags" {
  for_each = {
    "Name"      = var.instance_name
    "ManagedBy" = "Terraform"
  }

  resource_id = aws_instance.server.primary_network_interface_id
  key         = each.key
  value       = each.value
}

# --- LÓGICA DA INTERFACE DE REDE (ENI) ADICIONAL ---
resource "aws_network_interface" "secondary_eni" {
  count     = var.create_additional_eni ? 1 : 0
  subnet_id = var.additional_eni_subnet_id != null ? var.additional_eni_subnet_id : var.subnet_id
  
  security_groups = length(var.additional_eni_security_group_ids) > 0 ? var.additional_eni_security_group_ids : (
    var.create_security_group ? concat([aws_security_group.ec2_sg[0].id], var.additional_security_group_ids) : var.additional_security_group_ids
  )

  tags = merge(
    local.common_tags,
    { Name = "${var.instance_name}-secondary-eni" }
  )
}

resource "aws_network_interface_attachment" "secondary_eni_attach" {
  count                = var.create_additional_eni ? 1 : 0
  instance_id          = aws_instance.server.id
  network_interface_id = aws_network_interface.secondary_eni[0].id
  device_index         = var.additional_eni_device_index
}