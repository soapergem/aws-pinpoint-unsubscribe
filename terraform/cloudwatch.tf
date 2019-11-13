resource "aws_api_gateway_method_settings" "unsubscribe" {
  # turn this on if you want API gateway logs to appear in cloudwatch
  count = 0

  rest_api_id = aws_api_gateway_rest_api.unsubscribe.id
  stage_name  = aws_api_gateway_deployment.unsubscribe.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }

  depends_on = ["aws_api_gateway_account.apigateway"]
}

resource "aws_api_gateway_account" "apigateway" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}

resource "aws_iam_role" "cloudwatch" {
  name               = "api_gateway_cloudwatch_global"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_principal.json
}

data "aws_iam_policy_document" "cloudwatch_principal" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name   = "default"
  role   = aws_iam_role.cloudwatch.id
  policy = data.aws_iam_policy_document.cloudwatch_logs.json
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents",
    ]
  }
}

resource "aws_cloudwatch_log_group" "unsubscribe" {
  name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.unsubscribe.id}/${var.stage_name}"
}
