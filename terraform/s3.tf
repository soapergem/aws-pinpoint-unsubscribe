resource "aws_s3_bucket" "swap" {
  bucket = "pinpoint-${local.account_id}-swap"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "swap" {
  bucket = aws_s3_bucket.swap.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "swap" {
  bucket = aws_s3_bucket.swap.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "swap" {
  depends_on = [aws_s3_bucket_ownership_controls.swap]

  bucket = aws_s3_bucket.swap.id
  acl    = "private"
}