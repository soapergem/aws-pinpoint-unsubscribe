resource "aws_lambda_function" "unsubscribe" {
  filename      = "lambda.zip"
  function_name = "pinpoint_unsubscribe_handler"
  description   = "Managed by Terraform"
  role          = aws_iam_role.lambda_dynamo.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.7"
  timeout       = "30"

  environment {
    variables = {
      INDEX_NAME = join("", aws_dynamodb_table.email_list.global_secondary_index[*].name)
      TABLE_NAME = aws_dynamodb_table.email_list.name
    }
  }
}
