variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
  default     = "resized-images-staging"
}
variable "enviroment" {
  type        = string
  description = "Name of the Lambda function"
  default     = "staging"
}

variable "function_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "lambda-image-resizer-staging"
}

variable "api_name" {
  type        = string
  description = "Name of the Lambda function"
  default     = "resized-images"
}
variable "region" {
  type        = string
  description = "Name of the region"
  default     = "us-east-1"
}


variable "resize-prefix" {
  type        = string
  description = "Name of the resized image prefix"
  default     = "resize"
}
