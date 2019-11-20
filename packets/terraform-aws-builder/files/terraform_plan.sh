. ./shared.sh;

# For Terraform to work, AWS environment variables need to be set. Default profile doesn't work
configure_aws_credentials;

terraform_plan;
