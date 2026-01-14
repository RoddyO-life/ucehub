# S3 Module for UCEHub
# Creates buckets for document storage (PDFs, justifications)

# ============================================================================
# DOCUMENTS BUCKET (for absence justifications PDFs)
# ============================================================================

resource "aws_s3_bucket" "documents" {
  bucket = "${var.project_name}-documents-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-documents-${var.environment}"
      Type = "Documents"
    }
  )
}

# Block public access
resource "aws_s3_bucket_public_access_block" "documents" {
  bucket = aws_s3_bucket.documents.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle policy to clean old documents
resource "aws_s3_bucket_lifecycle_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    id     = "delete-old-documents"
    status = "Enabled"

    filter {
      prefix = ""  # Apply to all objects
    }

    expiration {
      days = 365  # Keep documents for 1 year
    }

    noncurrent_version_expiration {
      noncurrent_days = 90  # Keep old versions for 90 days
    }
  }
}

# CORS configuration for direct uploads
resource "aws_s3_bucket_cors_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST"]
    allowed_origins = ["*"]  # In production, restrict to specific domains
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# ============================================================================
# DATA SOURCES
# ============================================================================

data "aws_caller_identity" "current" {}
