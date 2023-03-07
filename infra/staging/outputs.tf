
output "name" {
  value = data.aws_s3_bucket.skult-cards.id
}

output "api_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}

variable "test_variable" {
  default = "test"

}

output "s3_url" {
  value = "http://${aws_s3_bucket.bucket.website_endpoint}"
}
