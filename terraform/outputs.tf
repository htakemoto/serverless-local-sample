output "lambda_api_version" {
  description = "lambda-api version"
  value = aws_lambda_function.api.version
}

output "lambda_api_invoke_arn" {
  description = "lambda-api invoke_arn"
  value = aws_lambda_function.api.invoke_arn
}

output "qualified_invoke_arn" {
  description = "lambda-api qualified_invoke_arn"
  value = aws_lambda_function.api.qualified_invoke_arn
}
