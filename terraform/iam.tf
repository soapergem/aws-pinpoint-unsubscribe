data "aws_iam_policy_document" "lambda_principal" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_dynamo" {
  name               = "lambda_dynamo"
  assume_role_policy = data.aws_iam_policy_document.lambda_principal.json
}

data "aws_iam_policy" "basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_dynamo.name
  policy_arn = data.aws_iam_policy.basic_execution.arn
}

data "aws_iam_policy" "vpc_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_dynamo.name
  policy_arn = data.aws_iam_policy.vpc_execution.arn
}

data "aws_iam_policy_document" "lambda_dynamo" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda_dynamo" {
  name   = "DynamoDBAccess"
  role   = aws_iam_role.lambda_dynamo.id
  policy = data.aws_iam_policy_document.lambda_dynamo.json
}

data "aws_iam_policy_document" "pinpoint_principal" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pinpoint.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "pinpoint_importer" {
  name               = "pinpoint_importer"
  assume_role_policy = data.aws_iam_policy_document.pinpoint_principal.json
}

data "aws_iam_policy_document" "pinpoint_importer" {
  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
    ]

    resources = ["arn:aws:s3:::${aws_s3_bucket.swap.id}"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
    ]

    resources = ["arn:aws:s3:::${aws_s3_bucket.swap.id}/*"]
  }
}

resource "aws_iam_role_policy" "pinpoint_importer" {
  name   = "DynamoDBAccess"
  role   = aws_iam_role.pinpoint_importer.id
  policy = data.aws_iam_policy_document.pinpoint_importer.json
}
