resource "aws_s3_bucket" "swap" {
  bucket = "pinpoint-${local.account_id}-swap"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
