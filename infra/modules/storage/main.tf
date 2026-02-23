variable "backup_bucket_name" { default = "platform-backups-nbg1" }

# In Hetzner, this usually maps to a generic S3-compatible provider 
# or an external AWS S3 bucket for cross-cloud durability.
# Example assumes AWS S3 module usage.

resource "aws_s3_bucket" "backups" {
  bucket = var.backup_bucket_name
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    expiration {
      days = 90
    }
  }
}

output "backup_bucket_domain" { value = aws_s3_bucket.backups.bucket_regional_domain_name }
output "backup_bucket_name" { value = aws_s3_bucket.backups.id }
