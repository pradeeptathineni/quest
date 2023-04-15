output "service_terraform_state_bucket" {
  value = aws_s3_bucket.service_terraform_state.bucket
}
