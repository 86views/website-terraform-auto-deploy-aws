terraform {
  backend "s3" {
    bucket         = "tf-state-7afc2a05"
    key            = "autodeploy-website-aws-cicd/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}