variable "bucket_name" {
  description = "Nome único do bucket S3."
  type        = string
}

variable "force_destroy" {
  description = "Permite destruir o bucket mesmo que ele contenha objetos."
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Habilita ou desabilita o versionamento do bucket."
  type        = bool
  default     = true
}

variable "sse_algorithm" {
  description = "Algoritmo de criptografia padrão (ex: AES256 ou aws:kms)."
  type        = string
  default     = "AES256"
}

variable "kms_master_key_id" {
  description = "ARN ou ID da chave KMS caso sse_algorithm seja aws:kms."
  type        = string
  default     = null
}

variable "bucket_key_enabled" {
  description = "Usa S3 Bucket Keys para reduzir custos de chamadas KMS."
  type        = bool
  default     = true
}

variable "block_public_acls" {
  description = "Bloqueia ACLs públicas."
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Bloqueia políticas de bucket públicas."
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Ignora ACLs públicas existentes."
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Restringe o bucket caso tenha políticas públicas."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Lista de regras de ciclo de vida para transição e expiração de objetos."
  type = list(object({
    id      = string
    enabled = bool
    prefix  = optional(string, null)
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration_days = optional(number, null)
    noncurrent_version_transitions = optional(list(object({
      noncurrent_days = number
      storage_class   = string
    })), [])
    noncurrent_version_expiration_days = optional(number, null)
  }))
  default = []
}

variable "custom_bucket_policy" {
  description = "Documento JSON de política IAM adicional para o bucket."
  type        = string
  default     = null
}

variable "tags" {
  description = "Mapa de tags para aplicar aos recursos."
  type        = map(string)
  default     = {}
}