#set ($providerAlias = $instance.getAttribute("provider_alias"))
variable "${providerAlias}_aws_access_key" {}
variable "${providerAlias}_aws_secret_key" {}
variable "${providerAlias}_aws_session_token" {}

provider "aws" {
  alias = "$providerAlias"

  region     = "$instance.getAttribute("provider_region")"
  access_key = var.${providerAlias}_aws_access_key
  secret_key = var.${providerAlias}_aws_secret_key
  token      = var.${providerAlias}_aws_session_token
}

data "aws_caller_identity" "$providerAlias" {
  $instance.getAttribute("provider_line")
}
