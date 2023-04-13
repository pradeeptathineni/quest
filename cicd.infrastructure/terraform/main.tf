# Configure AWS provider
provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# Create S3 bucket where the Terraform configuration files will be stored and versioned
resource "aws_s3_bucket" "terraform_config_bucket" {
  bucket = "terraform-config-bucket-${local.account_id}"
}

# Create S3 bucket where the Terraform state file will be stored and versioned
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket = "terraform-state-bucket-${local.account_id}"
}

# Create IAM role that will be used by the CICD pipeline
resource "aws_iam_role" "cicd_iam_role" {
  name = "cicd_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Create IAM policy that grants the CICD pipeline permissions to manage the two Terraform buckets
resource "aws_iam_policy" "cicd_iam_policy" {
  name = "cicd_iam_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.terraform_config_bucket.arn}",
          "${aws_s3_bucket.terraform_config_bucket.arn}/*",
          "${aws_s3_bucket.terraform_state_bucket.arn}",
          "${aws_s3_bucket.terraform_state_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach IAM policy to IAM role
resource "aws_iam_role_policy_attachment" "cicd_iam_role_policy_attachment" {
  policy_arn = aws_iam_policy.cicd_iam_policy.arn
  role       = aws_iam_role.cicd_iam_role.name
}

resource "aws_codestarconnections_connection" "github_connection" {
  name          = "GithubConnection"
  provider_type = "GitHub"
}

# owner_account_id      = local.account_id
# provider_endpoint     = "https://api.github.com"
# authentication_type   = "PersonalAccessToken"
# personal_access_token = "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"

# Create CodePipeline for the CICD workflow that will manage the Terraform state file
resource "aws_codepipeline" "cicd_pipeline" {
  name = "cicd_pipeline"
  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.terraform_state_bucket.bucket
  }
  role_arn = aws_iam_role.cicd_iam_role.arn
  stage {
    name = "Source"
    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_artifact"]
      configuration = {
        BranchName       = "main"
        FullRepositoryId = "orgname/reponame"
        ConnectionArn    = aws_codestarconnections_connection.github_connection.arn
      }
      run_order = 1
    }
  }
  stage {
    name = "Build"
    action {
      name            = "BuildAction"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source_artifact"]
      configuration = {
        ProjectName   = "terraform_build_project"
        PrimarySource = "codebuild_source"
        EnvironmentVariables = jsonencode([
          {
            "name"  = "AWS_DEFAULT_REGION"
            "value" = "${var.region}"
          }
        ])
      }
      run_order = 2
    }
  }
  stage {
    name = "Deploy"
    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "Terraform"
      version         = "1"
      input_artifacts = ["source_artifact", "build_artifact"]
      configuration = {
        BackendType = "s3"
        BackendConfig = jsonencode({
          bucket  = aws_s3_bucket.terraform_state_bucket.bucket
          key     = "terraform.tfstate"
          region  = "${var.region}"
          encrypt = true
        })
        TerraformCommand     = "apply"
        TerraformArguments   = "-auto-approve"
        AwsProviderArguments = "-region=${var.region}"
      }
      run_order = 3
    }
  }
}

data "template_file" "terraform_buildspec" {
  template = <<EOF
version: 0.2

phases:
  install:
    runtime-versions:
      terraform: 1.0.3
    commands:
    - mkdir out
    - terraform --version
  build:
    commands:
    - terraform init -backend-config="bucket=${aws_s3_bucket.terraform_state_bucket.bucket}" -backend-config="key=terraform.tfstate" -backend-config="region=${var.region}" -backend-config="encrypt=true"
    - terraform validate
    - terraform fmt -check=true
    - terraform plan
    - terraform output > out/outputs.txt
  post_build:
    commands:
    - cd out
    - zip -r terraform-config.zip .
    - aws s3 cp terraform-config.zip s3://${aws_s3_bucket.terraform_config_bucket.bucket}/terraform/terraform-config.zip
EOF
}

resource "aws_s3_object" "terraform_buildspec" {
  key     = "awscodebuild/buildspec.yml"
  bucket  = aws_s3_bucket.terraform_config_bucket.bucket
  content = data.template_file.terraform_buildspec.rendered
}

# # Create CodePipeline for the CICD workflow that will manage Terraform configuration files
# resource "aws_codebuild_project" "terraform_build_project" {
#   name = "terraform_build_project"
#   environment {
#     compute_type = "BUILD_GENERAL1_SMALL"
#     image        = "hashicorp/terraform:light"
#     type         = "LINUX_CONTAINER"
#   }
#   service_role = aws_iam_role.cicd_iam_role.arn
#   artifacts {
#     type      = "S3"
#     location  = aws_s3_bucket.terraform_config_bucket.bucket
#     name      = "terraform-config"
#     packaging = "ZIP"
#   }
#   source {
#     type                = "S3"
#     location            = aws_s3_bucket.terraform_config_bucket.bucket
#     buildspec           = "awscodebuild/buildspec.yml"
#     report_build_status = true
#   }
#   cache {
#     type     = "S3"
#     location = "terraform-cache"
#   }
#   build_timeout = 60
#   depends_on = [
#     data.template_file.terraform_buildspec
#   ]
# }
