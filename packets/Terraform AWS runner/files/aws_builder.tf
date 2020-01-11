
provider "aws" {
  region = "$instance.getAttribute("aws_region")"
  version = "$instance.getAttribute("aws_provider_version")"
}

#if ($extra_terraform)
$extra_terraform
#end

#foreach ($stateInstance in $instance.getInstancesByAttributeVelocityNames("state_velocity_names", false, false))
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