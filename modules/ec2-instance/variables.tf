variable "instance_name"     { type = string }
variable "ami_id"   { type = string }
variable "instance_type"     { type = string }
variable "os_disk_size_gb"   { type = number }
variable "data_disk_size_gb" { type = number }
variable "assign_public_ip"  { type = bool }
variable "vpc_id"            { type = string }
variable "subnet_id"         { type = string }
variable "private_key_save_path" { type = string }

variable "custom_tags" {
  description = "Tags personalizadas para aplicar aos recursos da EC2."
  type        = map(string)
  default     = {} # Define um mapa vazio como padrão, tornando esta variável opcional.
}

variable "tag_backup" {
  description = "Tags dedicadas para operação de BACKUP"
  type        = map(string)
  default     = {} # Define um mapa vazio como padrão, tornando esta variável opcional.
}

variable "standard_tags" {
  description = "Tags personalizadas para aplicar aos recursos da EC2."
  type        = map(string)
  default     = {} # Define um mapa vazio como padrão, tornando esta variável opcional.
}

variable "install_cloudwatch_agent" {
  description = "Se true, instala e configura o CloudWatch Agent. Se false, pula esta etapa."
  type        = bool
  default     = false
}

variable "additional_security_group_ids" {
  description = "Lista de IDs de Security Groups existentes para anexar à instância, além do grupo padrão."
  type        = list(string)
  default     = [] # O padrão é uma lista vazia, tornando este parâmetro opcional.
}

# Permite a inclusao de uma regra personalizada no security group
variable "extra_ingress" {
  type    = map(list(string))
  default = {} # Vazio por padrão = impacto zero no que já existe
}

variable "key_name_aws" {
  description = "Nome da chave já existente na AWS Console. Deixe vazio para gerar uma nova."
  type        = string
  default     = "" # O valor padrão vazio garante que a geração automática continue funcionando
}

variable "user_data_script" {
  description = "Script de inicialização (PowerShell para Windows ou Bash para Linux)"
  type        = string
  default     = null
}

variable "block_default_ingress" {
  type        = bool
  description = "Quando true, remove a regra padrão que libera todo o tráfego de entrada."
  default     = false # 👈 Torna o parâmetro opcional e mantém o padrão atual
}

variable "create_security_group" {
  type        = bool
  default     = true
  description = "Controla se o módulo deve criar um Security Group padrão para a instância"
}

variable "iam_instance_profile_name" {
  type    = string
  default = "" # 👈 Fundamental estar vazio por padrão!
}

variable "create_additional_eni" {
  description = "Flag opcional para criar uma ENI adicional"
  type        = bool
  default     = false
}

variable "additional_eni_subnet_id" {
  description = "Subnet da ENI adicional. Se omitido, usa a mesma subnet da instância"
  type        = string
  default     = null
}

variable "additional_eni_security_group_ids" {
  description = "Security groups para a nova ENI"
  type        = list(string)
  default     = []
}

variable "additional_eni_device_index" {
  description = "Índice da placa de rede (1 é a segunda placa)"
  type        = number
  default     = 1
}

variable "ebs_volumes" {
  description = "Volumes EBS adicionais para a EC2"
  type = map(object({
    device_name = string
    size        = number
    type        = optional(string, "gp3")
    encrypted   = optional(bool, true)
    kms_key_id  = optional(string, null)
    iops        = optional(number, null)
    throughput  = optional(number, null)
    name        = optional(string, null) # Preencha se quiser sobrescrever a Tag Name
    tags        = optional(map(string), {})
  }))
  default = {}
}