resource "aws_dynamodb_table" "email_list" {
  name           = "PinpointEmailList"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "email_address"

  attribute {
    name = "email_address"
    type = "S"
  }

  attribute {
    name = "email_hash"
    type = "S"
  }

  global_secondary_index {
    name            = "email_hash-index"
    hash_key        = "email_hash"
    read_capacity   = 5
    write_capacity  = 5
    projection_type = "ALL"
  }
}
