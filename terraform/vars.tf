variable "app_name" {
  default = "serverless-local-sample"
}

variable "region" {
  default = "us-east-1"
}

variable "aws_account_id" {
  default = "0123456789"
}

variable "app_version" {
  default = "0.0.0"
}

variable "agw_cache_enabled" {
  default = false
}

variable "lambda_runtime" {
  default = "nodejs18.x"
}

variable "log_retention_in_days" {
  default = 90
  description = "CloudWatch Log retention period in days"
}