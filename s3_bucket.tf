module "app_storage" {
  source = "./modules/s3"

  bucket_name        = "storage-ed-app-dev"
  versioning_enabled = false

  sse_algorithm      = "AES256"
  bucket_key_enabled = true

  lifecycle_rules = [
    {
      id      = "archive-old-objects"
      enabled = true
      prefix  = "logs/"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]
      expiration_days = 365
      noncurrent_version_expiration_days = 60
    }
  ]

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}