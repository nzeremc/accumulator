# S3 Bucket for SQL scripts and static data files
resource "aws_s3_bucket" "data" {
  bucket = var.bucket_name

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-data-bucket"
    }
  )
}

# Enable versioning
resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Disabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy for old versions
resource "aws_s3_bucket_lifecycle_configuration" "data" {
  count  = var.versioning_enabled ? 1 : 0
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Create folder structure with placeholder objects
resource "aws_s3_object" "init_folder" {
  bucket  = aws_s3_bucket.data.id
  key     = "init/"
  content = ""

  tags = merge(
    var.tags,
    {
      Name = "init-folder"
    }
  )
}

resource "aws_s3_object" "static_data_folder" {
  bucket  = aws_s3_bucket.data.id
  key     = "static-data/"
  content = ""

  tags = merge(
    var.tags,
    {
      Name = "static-data-folder"
    }
  )
}