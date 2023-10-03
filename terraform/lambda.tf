resource "aws_lambda_function" "unsubscribe" {
  filename      = data.archive_file.unsubscribe_lambda.output_path
  function_name = "pinpoint_unsubscribe_handler"
  description   = "Managed by Terraform"
  role          = aws_iam_role.lambda_dynamo.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  timeout       = "30"

  environment {
    variables = {
      INDEX_NAME = join("", aws_dynamodb_table.email_list.global_secondary_index[*].name)
      TABLE_NAME = aws_dynamodb_table.email_list.name
    }
  }
}

data "archive_file" "unsubscribe_lambda" {
  type        = "zip"
  source_file = "../lambda_function.py"
  output_path = "lambda.zip"
}
