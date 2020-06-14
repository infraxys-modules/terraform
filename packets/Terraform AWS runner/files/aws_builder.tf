#if ($instance.getAttribute("aws_provider_version") != "")
terraform {
  required_providers {
    aws = "$instance.getAttribute("aws_provider_version")"
    template = "~> 2.1"
  }
}

provider "aws" {
  region = "$instance.getAttribute("aws_region")"
}
#end

#if ($extra_terraform)
$extra_terraform
#end

#foreach ($stateInstance in $instance.getInstancesByAttributeVelocityNames("state_velocity_names", false, true))
#if ($stateInstance.packetKey == "TERRAFORM-S3-STATE")
data "terraform_remote_state" "$stateInstance.getAttribute("state_name")" {
backend = "s3"
config = {
bucket = "$stateInstance.getAttribute("state_s3_bucket")"
key = "$stateInstance.getAttribute("state_key")"
region = "$stateInstance.getAttribute("state_aws_region")"
}
}

#else
#set ($message = "Terraform state instance key '" + $stateInstance.packetKey + "' not supported")
$environment.throwException($message)
#end
#end