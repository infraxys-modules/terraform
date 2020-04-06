function get_and_set_terraform_aws_provider_credentials() {
	local aws_profile="$instance.getAttribute("aws_profile")";
	local provider_alias="$instance.getAttribute("provider_alias")";
	
#[[	
	log_info "Storing the current AWS environment.";
	local old_aws_profile="$AWS_PROFILE";
	local old_aws_default_region="$AWS_DEFAULT_REGION";
	local old_aws_secret_access_key="$AWS_SECRET_ACCESS_KEY";
	local old_aws_access_key_id="$AWS_ACCESS_KEY_ID";
	local old_aws_session_token="$AWS_SESSION_TOKEN";

	set_aws_profile --profile_name "$aws_profile";
	export TF_VAR_${provider_alias}_aws_access_key="$AWS_ACCESS_KEY_ID";
	export TF_VAR_${provider_alias}_aws_secret_key="$AWS_SECRET_ACCESS_KEY";
	export TF_VAR_${provider_alias}_aws_session_token="$AWS_SESSION_TOKEN";

	log_info "Restoring the previous AWS environment.";
	export AWS_PROFILE="$old_aws_profile";
	export AWS_DEFAULT_REGION="$old_aws_default_region";
	export AWS_SECRET_ACCESS_KEY="$old_aws_secret_access_key";
	export AWS_ACCESS_KEY_ID="$old_aws_access_key_id";
	export AWS_SESSION_TOKEN="$old_aws_session_token";
}

get_and_set_terraform_aws_provider_credentials;
]]#