# Image Resizer Lambda with Terraform, Sharp, and TypeScript and AWS Lambda

This project deploys a lambda function that resizes images on the fly using Sharp library and TypeScript as a language. The lambda function is triggered by CloudFront origin request and it resizes the image based on the query string parameters.

## Prerequisites

Before you can deploy this project, you need to have the following prerequisites:

- `aws` CLI tool installed and configured with your AWS credentials. You can download the CLI tool from [here](https://aws.amazon.com/cli/).
- `sam` CLI tool installed. You can download the CLI tool from [here](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html).
- `terraform` CLI tool installed. You can download the CLI tool from [here](https://www.terraform.io/downloads.html).
- A source S3 bucket which contains the original images that you want to resize.
- A CloudFront distribution which points to the source S3 bucket.

## Getting Started

To get started with this project, clone the repository and navigate to the root directory of the project.

```sh
git clone https://github.com/darklight147/Terraform-AWS-lambda-image-resizing-on-the-fly.git terraform-image-resize


cd terraform-image-resize
```

## Project structure

```sh
~/Documents/workspace/terraform-image-resize main* ❯ tree -I node_modules
.
├── README.md
├── deploy.sh
├── destroy.sh
├── infra
│   ├── production
│   └── staging
│       ├── lambda.zip
│       ├── lib
│       │   └── sharp-layer.zip
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfstate
│       ├── terraform.tfstate.backup
│       ├── terraform.tfvars
│       └── variables.tf
└── lambda-resizer
    ├── README.md
    ├── events
    │   └── event.json
    ├── resizer
    │   ├── app.ts
    │   ├── jest.config.ts
    │   ├── package-lock.json
    │   ├── package.json
    │   ├── tests
    │   │   └── unit
    │   │       └── test-handler.test.ts
    │   └── tsconfig.json
    ├── samconfig.toml
    └── template.yaml

10 directories, 21 files
```

You'll need to give execution access to the `.sh` files

```sh
chmod +x *.sh
```

## Running the project

```sh
./deploy.sh
```

PS: you can fill in your custom variables by creating a `terraform.tfvars` at `./infra/staging/terraform.tfvars`

## Destroying the created resources

```sh
./destroy.sh
```

## Contribution Guide
