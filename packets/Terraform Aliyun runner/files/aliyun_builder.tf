#if ($instance.getAttribute("alicloud_provider_version") != "")
terraform {
  required_providers {
    alicloud = "$instance.getAttribute("alicloud_provider_version")"
    template = "~> 2.1"
  }
}

provider "alicloud" {
  profile                 = "$instance.getAttribute("aliyun_profile_name")"
  region                  = "$instance.getAttribute("aliyun_region")"
  skip_region_validation  = false
}
#end

#if ($extra_terraform)
$extra_terraform
#end

#foreach ($stateInstance in $instance.getInstancesByAttributeVelocityNames("state_velocity_names", false, true))
#if ($stateInstance.packetKey == "TERRAFORM-ALIYUN-OSS-STATE")
data "terraform_remote_state" "$stateInstance.getAttribute("state_name")" {
    backend   = "oss"
    config    = {
    	profile = "$instance.getAttribute("aliyun_profile_name")"
		bucket = "$stateInstance.getAttribute("state_bucket")"
		prefix = "$stateInstance.getAttribute("state_prefix")"
		key = "$stateInstance.getAttribute("state_key")"
		region = "$stateInstance.getAttribute("state_region")"
    }
    outputs   = {}
    workspace = "default"
}

#else
#set ($message = "Terraform state instance key '" + $stateInstance.packetKey + "' not supported")
$environment.throwException($message)
#end
#end