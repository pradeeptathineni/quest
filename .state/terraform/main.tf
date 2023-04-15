resource "aws_s3_bucket" "service_terraform_state" {
  bucket        = "${var.service}-service-tfstate-042023"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "service_bucket_versioning" {
  bucket = aws_s3_bucket.service_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "service_bucket_block" {
  bucket                  = aws_s3_bucket.service_terraform_state.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "service_bucket_policy" {
  bucket = aws_s3_bucket.service_terraform_state.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "${aws_s3_bucket.service_terraform_state.arn}",
          "${aws_s3_bucket.service_terraform_state.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "service_bucket_sse" {
  bucket = aws_s3_bucket.service_terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
