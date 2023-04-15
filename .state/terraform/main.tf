resource "aws_s3_bucket" "service_terraform_state" {
  bucket        = "${var.service}-service-tfstate-042023"
  force_destroy = true
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "service_bucket_block" {
  bucket                  = aws_s3_bucket.service_terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
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
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ],
        "Resource" : "${aws_s3_bucket.service_terraform_state.arn}"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteObject"
        ],
        "Resource" : "${aws_s3_bucket.service_terraform_state.arn}/*"
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


resource "aws_s3_bucket" "cicd_terraform_state" {
  bucket        = "${var.service}-cicd-tfstate-042023"
  force_destroy = true
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cicd_bucket_block" {
  bucket                  = aws_s3_bucket.cicd_terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "cicd_bucket_policy" {
  bucket = aws_s3_bucket.cicd_terraform_state.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ],
        "Resource" : "${aws_s3_bucket.cicd_terraform_state.arn}"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "*"
        },
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObjectVersion",
          "s3:DeleteObject"
        ],
        "Resource" : "${aws_s3_bucket.cicd_terraform_state.arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cicd_bucket_sse" {
  bucket = aws_s3_bucket.cicd_terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
