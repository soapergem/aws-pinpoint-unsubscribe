resource "aws_api_gateway_rest_api" "unsubscribe" {
  name        = "Pinpoint Email Unsubscribe"
  description = "Managed by Terraform"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "unsubscribe" {
  rest_api_id = "${aws_api_gateway_rest_api.unsubscribe.id}"

  depends_on = [
    "aws_api_gateway_method.root",
    "aws_api_gateway_integration.root",
    "aws_api_gateway_method.hash",
    "aws_api_gateway_integration.hash",
  ]
}

resource "aws_api_gateway_stage" "unsubscribe" {
  rest_api_id   = aws_api_gateway_rest_api.unsubscribe.id
  deployment_id = aws_api_gateway_deployment.unsubscribe.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.unsubscribe.arn
    format          = templatefile("templates/common_log_format.txt", {})
  }
}

########################################

resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.unsubscribe.id
  resource_id   = aws_api_gateway_rest_api.unsubscribe.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  rest_api_id             = aws_api_gateway_rest_api.unsubscribe.id
  resource_id             = aws_api_gateway_rest_api.unsubscribe.root_resource_id
  http_method             = aws_api_gateway_method.root.http_method
  integration_http_method = "POST"
  uri                     = aws_lambda_function.unsubscribe.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = "AWS"

  request_templates = {
    "application/json" = templatefile("templates/integration_request.vtl", { hash_id = "" })
  }
}

resource "aws_api_gateway_method_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.unsubscribe.id
  resource_id = aws_api_gateway_rest_api.unsubscribe.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "root" {
  rest_api_id = aws_api_gateway_rest_api.unsubscribe.id
  resource_id = aws_api_gateway_rest_api.unsubscribe.root_resource_id
  http_method = aws_api_gateway_method.root.http_method
  status_code = aws_api_gateway_method_response.root.status_code
  depends_on  = ["aws_api_gateway_integration.root"]

  response_parameters = {
    "method.response.header.Content-Type" = "'text/html'"
  }

  response_templates = {
    "text/html" = templatefile("templates/integration_response.vtl", {})
  }
}

resource "aws_lambda_permission" "root" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unsubscribe.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.unsubscribe.id}/*/${aws_api_gateway_method.root.http_method}/"
}

########################################

resource "aws_api_gateway_resource" "hash" {
  rest_api_id = aws_api_gateway_rest_api.unsubscribe.id
  parent_id   = aws_api_gateway_rest_api.unsubscribe.root_resource_id
  path_part   = "{hash_id}"
}

resource "aws_api_gateway_method" "hash" {
  rest_api_id   = aws_api_gateway_rest_api.unsubscribe.id
  resource_id   = aws_api_gateway_resource.hash.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "hash" {
  rest_api_id             = aws_api_gateway_rest_api.unsubscribe.id
  resource_id             = aws_api_gateway_resource.hash.id
  http_method             = aws_api_gateway_method.hash.http_method
  integration_http_method = "POST"
  uri                     = aws_lambda_function.unsubscribe.invoke_arn
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = "AWS"

  request_templates = {
    "application/json" = templatefile("templates/integration_request.vtl", { hash_id = "$input.params('hash_id')" })
  }
}

resource "aws_api_gateway_method_response" "hash" {
  rest_api_id = aws_api_gateway_rest_api.unsubscribe.id
  resource_id = aws_api_gateway_resource.hash.id
  http_method = aws_api_gateway_method.hash.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_integration_response" "hash" {
  rest_api_id = aws_api_gateway_rest_api.unsubscribe.id
  resource_id = aws_api_gateway_resource.hash.id
  http_method = aws_api_gateway_method.hash.http_method
  status_code = aws_api_gateway_method_response.hash.status_code
  depends_on  = ["aws_api_gateway_integration.hash"]

  response_parameters = {
    "method.response.header.Content-Type" = "'text/html'"
  }

  response_templates = {
    "text/html" = templatefile("templates/integration_response.vtl", {})
  }
}

resource "aws_lambda_permission" "hash" {
  statement_id  = "AllowExecutionFromAPIGatewayWithParameter"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.unsubscribe.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${local.account_id}:${aws_api_gateway_rest_api.unsubscribe.id}/*/${aws_api_gateway_method.hash.http_method}/*"
}
