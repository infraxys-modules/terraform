terraform {
  backend "s3" {
    bucket = "$s3_bucket"
    key = "$state_key"
    encrypt = "$instance.getAttributeAsBoolean("encrypt_state_file")"
region = "$aws_region"
}
}
