terraform {
  backend "s3" {
    bucket = "$instance.getAttribute("s3_bucket")"
    key = "$instance.getAttribute("state_key")"
    encrypt = "$instance.getAttributeAsBoolean("encrypt_state_file")"
region = "$instance.getAttribute("aws_region")"
}
}
