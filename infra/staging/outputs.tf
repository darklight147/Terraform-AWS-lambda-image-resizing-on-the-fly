
output "name" {
  value = data.aws_s3_bucket.source-bucket.id
}

output "target-bucket" {
  value = aws_s3_bucket.bucket.bucket
}

output "api_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}

variable "test_variable" {
  default = "test"

}

output "s3_url" {
  value = "http://${aws_s3_bucket_website_configuration.bucket.website_endpoint}"

  depends_on = [
    aws_s3_bucket.bucket
  ]
}
