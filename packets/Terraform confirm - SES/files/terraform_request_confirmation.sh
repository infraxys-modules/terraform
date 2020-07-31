
function request_ses_confirmation() {
	local email_template_file="$instance.getAttribute("email_template_file")";
	local email_addresses="$instance.getAttribute("email_addresses")";
	local email_from="$instance.getAttribute("from_email_address")";
	local email_subject_apply="$instance.getAttribute("email_subject_apply")";
	local email_subject_destroy="$instance.getAttribute("email_subject_destroy")";
	local region="$instance.getAttribute("aws_region")";
	
#[[

	export APPLY_URL="${infraxys_request_url}/ui?type=EXECUTE-ACTION&path=$module_branch_path_url_encoded&environmentId=$environment_id&containerId=$container_id&instanceId=$instance_id&filename=terraform_apply.sh";

    if [ ! $(which envsubst) ]; then
        apt-get install gettext-base;
    fi;

    export BUTTON_CAPTION="Apply this plan";
    export TITLE="Confirm Terraform plan";
    export PREVIEW_HEADER="Terraform plan";
    export EXTRA_TEXT="<source>$(cat "$TERRAFORM_PLAN_OUTPUT_FILE" | sed -n '/^------------------------------------------------------------------------$/,$p' | sed -z 's/\n/<br\/>/g')</source>";
    local sha="$(cat $TERRAFORM_PLAN_FILE | sha256sum)";
    echo "$sha" > "${TERRAFORM_PLAN_FILE}.sha";
    local argument=$(cat <<EOF
{
    "sha": "$sha",
    "requestor": "$APPLICATION_USER"
}
EOF
)
    local argument_base64="$(echo "$argument" | base64 -w 0 -)";

    APPLY_URL="$APPLY_URL&argument=$argument_base64";
    export FOOTER_1="";
    export FOOTER_2="";
	envsubst < "$email_template_file" > /tmp/mail.html;

	if [ "$TERRAFORM_ACTION" == "APPLY" ]; then
		send_mail --from "$email_from" --to "$email_addresses" --aws_region "$region" \
			--subject "$email_subject_apply" --mail_body_file "/tmp/mail.html";
	elif [ "$TERRAFORM_ACTION" == "DESTROY" ]; then
		send_mail --from "$email_from" --to "$email_addresses" --aws_region "$region" \
			--subject "$email_subject_destroy" --mail_body_file "/tmp/mail.html";
	else
		log_fatal "TERRAFORM_ACTION '$TERRAFORM_ACTION' is unknown. Only 'APPLY' and 'DESTROY' are supported.";
	fi;
}

request_ses_confirmation;

]]#