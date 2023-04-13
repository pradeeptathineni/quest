provider "circleci" {
  api_token = "YOUR_API_TOKEN"
}

data "template_file" "circleci_config" {
  template = file("circleci_config.yml.tpl")

  vars = {
    aws_region         = "us-east-1"
    aws_account_id     = "1234567890"
    aws_ecr_repository = "my-ecr-repo"
    aws_iam_role       = "my-iam-role"
    slack_webhook_url  = "https://hooks.slack.com/services/XXXXXXXXX/XXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXXX"
  }
}

resource "circleci_project" "example" {
  name      = "example"
  vcs_type  = "github"
  username  = "your-username"
  repo_name = "your-repo"
  config    = data.template_file.circleci_config.rendered
}
