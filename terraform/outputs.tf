output "dynamodb_table_name" {
  value = aws_dynamodb_table.email_list.name
}

output "pinpoint_app_id" {
  value = aws_pinpoint_app.default.application_id
}

output "pinpoint_iam_role" {
  value = aws_iam_role.pinpoint_importer.name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.swap.id
}

output "unsubscribe_url" {
  value = "${aws_api_gateway_deployment.unsubscribe.invoke_url}${var.stage_name}"
}
