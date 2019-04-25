data "terraform_remote_state" "vpc" {
  backend = "s3"
  config {
    bucket = "$instance.getAttribute("terraform_state_bucket")"
key = "$instance.getAttribute("terraform_state_folder")/$instance.getAttribute("vpc_terraform_state_name")"
region = "$instance.getAttribute("AWS_REGION")"
}
}