resource "aws_s3_bucket" "service_terraform_state" {
  bucket = "${var.service}-service-tfstate-042023"
  acl    = "private"
}

resource "aws_s3_bucket" "cicd_terraform_state" {
  bucket = "${var.service}-cicd-tfstate-042023"
  acl    = "private"
}
