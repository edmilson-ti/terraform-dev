output "bucket_id" {
  description = "O nome/ID do bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "O ARN do bucket S3."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "O nome de domínio do bucket."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "O nome de domínio regional do bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}