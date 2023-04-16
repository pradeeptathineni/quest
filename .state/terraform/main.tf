# Create a data source for the current AWS user
data "aws_caller_identity" "current" {}

# Create S3 bucket for storing Terraform state files
resource "aws_s3_bucket" "terraform_state_bucket" {
  bucket        = "rearc-quest-terraform-state-0423"
  force_destroy = true # delete the bucket even if it contains objects
}

# Enable versioning for the Terraform state bucket
resource "aws_s3_bucket_versioning" "state_bucket_versioning" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access to the Terraform state bucket
resource "aws_s3_bucket_public_access_block" "state_bucket_block" {
  bucket                  = aws_s3_bucket.terraform_state_bucket.id
  block_public_acls       = true # block public access to ACLs
  block_public_policy     = true # block public access to bucket policy
  ignore_public_acls      = true # ignore public ACLs when checking for bucket access
  restrict_public_buckets = true # prevent public access to the bucket itself
}

# Add a policy to the Terraform state bucket to allow only the current AWS user to perform any S3 actions on the bucket
resource "aws_s3_bucket_policy" "state_bucket_policy" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "${data.aws_caller_identity.current.arn}"
        },
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "${aws_s3_bucket.terraform_state_bucket.arn}",
          "${aws_s3_bucket.terraform_state_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Enable server-side encryption for the Terraform state bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket_sse" {
  bucket = aws_s3_bucket.terraform_state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
