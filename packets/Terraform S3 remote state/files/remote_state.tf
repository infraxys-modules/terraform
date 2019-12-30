terraform {
  backend "s3" {
    bucket = "$instance.getAttribute("state_s3_bucket")"
    key = "$instance.getAttribute("state_key")"
    encrypt = "$instance.getAttributeAsBoolean("state_encrypt_file")"
region = "$instance.getAttribute("state_aws_region")"
#if ($instance.getAttribute("state_profile") != "")
profile = "$instance.getAttribute("state_profile")"
#end
}
}
