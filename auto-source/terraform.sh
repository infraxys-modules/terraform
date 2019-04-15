function terraform_init() {
    check_required_variables terraform_version;
    export TERRAFORM="/usr/local/bin/terraform-$terraform_version";
    if [ ! -f "$TERRAFORM" ]; then
        log_info "Terraform version $terraform_version not available in this provisioning server Docker image. Installing it now.";
        curl -L -o /tmp/terraform.zip https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip;
        cd /tmp;
        unzip terraform.zip;
        mv terraform /usr/local/bin/terraform-${terraform_version};
        rm -f terraform.zip
        cd -;
    fi;
    $TERRAFORM init -no-color;
}

function terraform_plan() {
    terraform_init;
    $TERRAFORM plan -no-color;
}

function terraform_plan_destroy() {
    terraform_init;
    $TERRAFORM plan -destroy -no-color;
}

function terraform_apply() {
    local grant;
    #import_args "$@";
    #local grant="Apply VPC plan in PROD";
    if [ -n "$grant" ]; then
        log_debug "Checking if the current user has the necessary permissions to perform this action.";
        local has_rights="$(/tmp/infraxys/system/has_grant "$grant")";
        if [ "$has_rights" == "true" ]; then
            log_info "You are ALLOWED to execute terraform apply because you have grant '$grant'.";
            log_info "You are ALLOWED to execute terraform apply because you have grant '$grant'.";
        else
            log_error "You are NOT ALLOWED to execute terraform apply because you DO NOT HAVE grant '$grant'.";
            log_error "You are NOT ALLOWED to execute terraform apply because you DO NOT HAVE grant '$grant'.";
            exit 1;
        fi;
    fi;
    terraform_init;
    $TERRAFORM apply -no-color -auto-approve;
    terraform_get_output --do_init="false";
}

function terraform_destroy() {
    terraform_init;
    $TERRAFORM destroy -force -no-color;
    terraform_get_output --do_init="false";
}

function terraform_get_output() {
    local function_name="terraform_get_output" do_init="true";
    import_args "$@";
    [[ "$do_init" == "true" ]] && terraform_init;
    output="$($TERRAFORM output -json -no-color)";
    save_last_output --output_json "$output";
}

function save_last_output() {
    local function_name="save_last_output" output_json;
    import_args "$@";
    check_required_arguments $function_name output_json;
    #output_json="$(echo "$output_json" | jq -c '.')";
    update_instance_attribute --instance_id "$instance_db_id" --attribute_name "last_terraform_output" --attribute_value "$output_json" --compile_instance="true";
}

