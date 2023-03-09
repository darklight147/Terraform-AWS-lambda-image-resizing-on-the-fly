terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.57.0"
    }
  }
}

# Define variables



# Provider configuration
provider "aws" {
  region  = "us-east-1"
  profile = var.profile
}

provider "aws" {
  alias   = "eu-west-3"
  region  = "eu-west-3"
  profile = var.profile
}


resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = "${var.enviroment}"
  }
}

resource "aws_s3_bucket_acl" "bucket-acl" {
  bucket = aws_s3_bucket.bucket.id

  acl = "public-read"
}
data "aws_s3_bucket" "source-bucket" {
  bucket = var.source_bucket

  provider = aws.eu-west-3
}


resource "aws_iam_role" "lambda" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "lambda.amazonaws.com",
        },
        Effect : "Allow",
        Sid : "",
      },
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "apigateway.amazonaws.com",
        },
        Effect : "Allow",
        Sid : "",
      },
    ],
  })
}



# # IAM policy for S3 access
resource "aws_iam_policy" "s3_policy" {
  name = "s3-policy"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource : "arn:aws:logs:*:*:*",
      },
      {
        Effect : "Allow",
        Action : "s3:PutObject",
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*",
        ]
      },
      {
        Effect : "Allow",
        Action : "s3:PutObjectAcl",
        Resource = [
          aws_s3_bucket.bucket.arn,
          "${aws_s3_bucket.bucket.arn}/*",
        ]
      },
      {
        Effect : "Allow",
        Action : "s3:GetObject",
        Resource = [
          data.aws_s3_bucket.source-bucket.arn,
          "${data.aws_s3_bucket.source-bucket.arn}/*",
        ]
      }
    ],
  })
}

# # # IAM role policy attachment for Lambda function
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.s3_policy.arn
  role       = aws_iam_role.lambda.name
}



data "archive_file" "zip" {
  type        = "zip"
  source_dir  = "${path.module}/../../lambda-resizer/.aws-sam/build/HelloWorldFunction"
  output_path = "${path.module}/lambda.zip"
}

// sharp lambda layer
resource "aws_lambda_layer_version" "sharp" {
  layer_name               = "sharp"
  filename                 = "${path.module}/lib/sharp-layer.zip"
  compatible_architectures = ["x86_64"]
  compatible_runtimes      = ["nodejs16.x"]
  source_code_hash         = filebase64sha256("${path.module}/lib/sharp-layer.zip")
  license_info             = "Apache License 2.0"
  description              = "Sharp layer"
}


# S3 bucket configuration
resource "aws_lambda_function" "function" {
  function_name = var.function_name
  role          = aws_iam_role.lambda.arn
  handler       = "app.lambdaHandler"
  runtime       = "nodejs16.x"
  filename      = data.archive_file.zip.output_path

  layers = [
    aws_lambda_layer_version.sharp.arn
  ]


  timeout     = 10
  memory_size = 1536

  source_code_hash = filebase64sha256(data.archive_file.zip.output_path)



  environment {
    variables = {
      BUCKET_NAME        = data.aws_s3_bucket.source-bucket.id
      TARGET_BUCKET_NAME = aws_s3_bucket.bucket.id
      ALLOWED_DIMENSIONS = "100x100,200x200,300x300,400x400,500x500,600x600,700x700,800x800,900x900,1000x1000,150x150"
      CDN_URL            = var.cdn_url
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Gateway for Lambda function that resizes images"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# # API Gateway resource configuration
resource "aws_api_gateway_resource" "api_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.resize-prefix
}

resource "aws_api_gateway_resource" "api_resource2" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.api_resource.id
  path_part   = "{proxy+}"
}

# # API Gateway method configuration
resource "aws_api_gateway_method" "api_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_resource2.id
  http_method   = "ANY"
  authorization = "NONE"
}

# # API Gateway integration configuration
resource "aws_api_gateway_integration" "api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api_resource2.id
  http_method             = aws_api_gateway_method.api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.function.invoke_arn

  content_handling = "CONVERT_TO_TEXT"
}

# # API Gateway deployment configuration
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.api_integration,
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = var.enviroment

  variables = {
    "lambdaArn" = aws_lambda_function.function.invoke_arn
  }
}

resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "apigateway.amazonaws.com"
}




resource "aws_s3_bucket_website_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  index_document {
    suffix = "index.html"
  }

  routing_rules = jsonencode([
    {
      Condition : {
        HttpErrorCodeReturnedEquals : "404",
      },
      Redirect : {
        ReplaceKeyPrefixWith : "${var.enviroment}/${var.resize-prefix}/r?key=",
        HttpRedirectCode : "307",
        HostName : element(split("/", split("//", aws_api_gateway_deployment.api_deployment.invoke_url)[1]), 0),
        Protocol : "https",
      },
    },
  ])
}
