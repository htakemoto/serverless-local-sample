# Terraform State File Location

# terraform {
#   backend "s3" {
#     bucket = "terraform-us-east-1"
#     key    = "serverless-local-sample/terraform.tfstate"
#     region = "us-east-1"
#     encrypt = true
#   }
# }

# Variables

locals {
  env = lower(terraform.workspace)
  app_name = var.app_name
  region = var.region
  ssm_name_prefix = "/${local.env}/${var.app_name}"
  agw_name = "${var.app_name}-${local.env}"
  agw_stage_name = local.env
  agw_cache_enabled = var.agw_cache_enabled
  agw_cache_ttl_in_seconds = 10
  lambda_api_name = "${var.app_name}-api-${local.env}"
  lambda_sync_layer_name = "${var.app_name}-api-layer-${local.env}"
  lambda_runtime = var.lambda_runtime
  lambda_role_arn = "arn:aws:iam::${var.aws_account_id}:role/LambdaBasicRole"
  newrelic_lambda_layer_arn = var.newrelic_lambda_layer_arn
  dynamodb_table_name_user = "${local.app_name}-user-${local.env}"
  log_retention_in_days = var.log_retention_in_days
}

# SSM

resource "aws_ssm_parameter" "lambda_provisioned_concurrent_executions" {
  name  = "${local.ssm_name_prefix}/lambda-provisioned-concurrent-executions"
  description = "This initializes a requested number of execution environments so that they are prepared to respond immediately to your function's invocations."
  type  = "String"
  value = "0"
  overwrite = true

  lifecycle {
    ignore_changes = [
      value
    ]
  }
}

# API Gateway

resource "aws_api_gateway_rest_api" "default" {
  name = local.agw_name
  description = "Sample"
}

resource "aws_api_gateway_resource" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  parent_id   = aws_api_gateway_rest_api.default.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "default" {
  rest_api_id   = aws_api_gateway_rest_api.default.id
  resource_id   = aws_api_gateway_resource.default.id
  http_method   = "ANY"
  authorization = "NONE"
  api_key_required = true
  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "default" {
  rest_api_id             = aws_api_gateway_rest_api.default.id
  resource_id             = aws_api_gateway_resource.default.id
  http_method             = aws_api_gateway_method.default.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri = parseint(aws_ssm_parameter.lambda_provisioned_concurrent_executions.value, 10) == 0 ? aws_lambda_function.api.invoke_arn : aws_lambda_function.api.qualified_invoke_arn

  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }

  cache_namespace = "ApiGatewayMethodPathProxyNS"
  cache_key_parameters = [
    "method.request.path.proxy"
  ]
}

resource "aws_api_gateway_method_settings" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  stage_name  = aws_api_gateway_stage.default.stage_name
  method_path = "*/*"

  settings {
    caching_enabled = local.agw_cache_enabled
    cache_ttl_in_seconds = local.agw_cache_ttl_in_seconds
    cache_data_encrypted = false
    require_authorization_for_cache_control = true
    unauthorized_cache_control_header_strategy = "SUCCEED_WITH_RESPONSE_HEADER"
    throttling_rate_limit = 10000
    throttling_burst_limit = 5000
    metrics_enabled = true
    logging_level = "ERROR"
  }
}

resource "aws_api_gateway_stage" "default" {
  deployment_id = aws_api_gateway_deployment.default.id
  rest_api_id   = aws_api_gateway_rest_api.default.id
  stage_name    = local.agw_stage_name
  cache_cluster_enabled = local.agw_cache_enabled
  cache_cluster_size = "0.5"
}

resource "aws_api_gateway_deployment" "default" {
  rest_api_id = aws_api_gateway_rest_api.default.id
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.default.id,
      aws_api_gateway_method.default.id,
      aws_api_gateway_integration.default.id,
      aws_lambda_function.api.function_name,
      aws_lambda_function.api.version,
      aws_ssm_parameter.lambda_provisioned_concurrent_executions.value
    ]))
  }
  lifecycle {
    create_before_destroy = true
  }
}

# API Key Config

resource "aws_api_gateway_api_key" "default" {
  name = local.agw_name
}

resource "aws_api_gateway_usage_plan" "default" {
  name         = local.agw_name
  description  = "Usage plan for serverless local sample"

  api_stages {
    api_id = aws_api_gateway_rest_api.default.id
    stage  = aws_api_gateway_stage.default.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "default" {
  key_id        = aws_api_gateway_api_key.default.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.default.id
}

# Lambda Code Prep

data "archive_file" "lambda_function_api_zip" {
  type = "zip"
  source_dir = "../app-api/src"
  output_path = "./function-api.zip"
}

# Lambda Layer Prep

data "archive_file" "lambda_layer_zip_api" {
  type = "zip"
  source_dir = "../layer/api"
  output_path = "./layer-api.zip"
}

# Lambda Layer

resource "aws_lambda_layer_version" "api" {
  layer_name = local.lambda_api_layer_name
  filename = data.archive_file.lambda_layer_zip_api.output_path
  source_code_hash = data.archive_file.lambda_layer_zip_api.output_base64sha256
  compatible_runtimes = [local.lambda_runtime]
}

# Lambda API

resource "aws_lambda_function" "api" {
  function_name = local.lambda_api_name
  filename = data.archive_file.lambda_function_api_zip.output_path
  source_code_hash = data.archive_file.lambda_function_api_zip.output_base64sha256
  layers = [
    aws_lambda_layer_version.api.arn
  ]
  handler = "lambda.handler"
  memory_size = 3008
  runtime = local.lambda_runtime
  timeout = 60
  role = local.lambda_role_arn
  publish = parseint(aws_ssm_parameter.lambda_provisioned_concurrent_executions.value, 10) == 0 ? false : true

  environment {
    variables = {
      ENVIRONMENT = local.env
      APP_VERSION = var.app_version
      DB_NAME_USER = local.dynamodb_table_name_user
    }
  }
}

resource "aws_lambda_provisioned_concurrency_config" "api" {
  count                             = parseint(aws_ssm_parameter.lambda_provisioned_concurrent_executions.value, 10) == 0 ? 0 : 1
  function_name                     = aws_lambda_function.api.function_name
  provisioned_concurrent_executions = parseint(aws_ssm_parameter.lambda_provisioned_concurrent_executions.value, 10)
  qualifier                         = aws_lambda_function.api.version
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api.function_name
  principal     = "apigateway.amazonaws.com"
  qualifier     = parseint(aws_ssm_parameter.lambda_provisioned_concurrent_executions.value, 10) == 0 ? null : aws_lambda_function.api.version

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.default.execution_arn}/*/*"
}

# DynamoDB

resource "aws_dynamodb_table" "site" {
  name           = local.dynamodb_table_name_site
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "siteId"

  attribute {
    name = "siteId"
    type = "S"
  }

  tags = {
    Name        = "${local.app_name}"
    Environment = "${local.env}"
  }
}

resource "aws_dynamodb_table" "center" {
  name           = local.dynamodb_table_name_user
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name        = "${local.app_name}"
    Environment = "${local.env}"
  }
}

# CloudWatch Log

resource "aws_cloudwatch_log_group" "lambda_api_log" {
  name = "/aws/lambda/${local.lambda_api_name}"
  retention_in_days = local.log_retention_in_days
}
