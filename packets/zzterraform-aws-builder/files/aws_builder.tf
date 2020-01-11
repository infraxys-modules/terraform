terraform {
  backend "s3" {
    bucket = "$instance.getAttribute("terraform_state_bucket")"
key = "$instance.getAttribute("terraform_state_folder")/$instance.getAttribute("terraform_state_name")"
encrypt = "true"
region = "$instance.getAttribute("AWS_REGION")"
}
}

provider "aws" {
region = "$instance.getAttribute("aws_region")"
version = "~> 1.32"
}
