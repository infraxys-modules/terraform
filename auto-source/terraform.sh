TERRAFORM_INFRAXYS_MODULE_DIRECTORY="$(pwd)";
DEFAULT_TERRAFORM_VERSION="0.13.4";
process_netrc_variables; # make sure https-modules that are in GitHub Enterprise and/or private can be downloaded
export TF_PLUGIN_CACHE_DIR="/cache/project/terraform/plugin-cache";
TERRAFORM_PLAN_FILE="/cache/instance/terraform/last_terraform_plan";
TERRAFORM_PLAN_OUTPUT_FILE="/cache/instance/terraform/last_terraform_plan_output";
mkdir -p "/cache/instance/terraform";

function ensure_terraform() {
    local terraform_version;
    import_args "$@";
    check_required_arguments "ensure_terraform" terraform_version;

    export TERRAFORM="terraform-$terraform_version";
    if [ $(which "$TERRAFORM") ]; then
        log_info "Terraform version $terraform_version is already installed at $(which $TERRAFORM).";
    else
        log_info "Terraform version $terraform_version not available. Installing it now in the project cache.";
        mkdir /tmp/install_terraform
        curl -Lo /tmp/install_terraform/terraform.zip https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip;
        cd /tmp/install_terraform;
        unzip terraform.zip;
        mv terraform "/cache/project/bin/$TERRAFORM";
        chmod u+x "/cache/project/bin/$TERRAFORM";
        rm -Rf /tmp/install_terraform
        cd -;
        log_info "Terraform $terraform_version is available at $(which $TERRAFORM)";
    fi;
}

function terraform_init() {
    if [ -z "$terraform_version" ]; then
        log_info "Terraform version not specified. Using version $DEFAULT_TERRAFORM_VERSION";
        local terraform_version="$DEFAULT_TERRAFORM_VERSION";
    fi;
    mkdir -p "$TF_PLUGIN_CACHE_DIR";
    ensure_terraform --terraform_version "$terraform_version";
    export TERRAFORM="terraform-$terraform_version";
    $TERRAFORM init -no-color;
}
readonly -f terraform_init;

function remove_last_plan() {
    if [ -f "$TERRAFORM_PLAN_FILE" ]; then
        rm "$TERRAFORM_PLAN_FILE";
    fi;
    if [ -f "${TERRAFORM_PLAN_FILE}.sha" ]; then
        rm "${TERRAFORM_PLAN_FILE}.sha";
    fi;

    if [ -f "$TERRAFORM_PLAN_OUTPUT_FILE" ]; then
        rm "$TERRAFORM_PLAN_OUTPUT_FILE";
    fi;

}
readonly -f remove_last_plan;

function terraform_plan() {
    local destroy="false";
    import_args "$@";

    remove_last_plan;
    terraform_init;
    set +e; # exit code 2 indicates changes should be applied
    if [ "$destroy" == "true" ]; then
        $TERRAFORM plan -destroy -no-color -detailed-exitcode -out="$TERRAFORM_PLAN_FILE" | tee "$TERRAFORM_PLAN_OUTPUT_FILE"
        local plan_result="$?"
    else
        generate_vars_arguments;
        $TERRAFORM plan -no-color -detailed-exitcode $vars_arguments -out="$TERRAFORM_PLAN_FILE" | tee "$TERRAFORM_PLAN_OUTPUT_FILE";
        local plan_result="$?";
    fi;

    [[ "$plan_result" == "0" ]] && log_info "No changes to apply" && return;
    [[ "$plan_result" == "1" ]] && log_error "Errors detected during Terraform plan." && exit 1;
    changes_to_apply="true";
    set -e;
}
readonly -f terraform_plan;

function terraform_apply() {
    local grant destroy no_plan="false";
    import_args "$@";

    if [ "$no_plan" != "true" ]; then
        [[ ! -f "$TERRAFORM_PLAN_FILE" ]] && log_fatal "Unable to apply because plan file '$TERRAFORM_PLAN_FILE' doesn't exist.";
    fi;

    if [ -n "$grant" ]; then
        log_debug "Checking if the current user has the necessary permissions to perform this action.";
        local has_rights="$(/tmp/infraxys/system/has_grant "$grant")";
        if [ "$has_rights" == "true" ]; then
            log_info "You are ALLOWED to execute terraform apply because you have grant '$grant'.";
        else
            log_fatal "You are NOT ALLOWED to execute terraform apply because you DO NOT HAVE grant '$grant'.";
        fi;
    fi;

    if [ "$no_plan" != "true" ]; then
        if [ -f "${TERRAFORM_PLAN_FILE}.sha" ]; then
            validate_terraform_sha_file;
        fi;
    fi;

    terraform_init;
    generate_vars_arguments;
    execute_rego_validators --plan_file "$TERRAFORM_PLAN_FILE";
    if [ "$no_plan" != "true" ]; then
        log_info "Applying plan file "$TERRAFORM_PLAN_FILE";";
        $TERRAFORM apply -no-color $vars_arguments "$TERRAFORM_PLAN_FILE";
        local apply_result=$?;
        remove_last_plan;
    else
        $TERRAFORM apply -no-color -auto-approve $vars_arguments;
        local apply_result=$?;
    fi;

    log_info "Apply done";
    if [ "$apply_result" != "0" ]; then
        log_error "Terraform failed. Aborting.";
        exit 1;
    fi;

    if [ "$destroy" == "true" ]; then
        run_or_source_files --directory "$TERRAFORM_TEMP_DIR" --filename_pattern 'after_terraform_destroy*';
    else
        run_or_source_files --directory "$TERRAFORM_TEMP_DIR" --filename_pattern 'after_terraform_apply*';
    fi;
}
readonly -f terraform_apply;

function terraform_plan_confirm_apply() {
    local changes_to_apply="false";
    export TERRAFORM_ACTION="APPLY";
    terraform_plan;
    [[ "$changes_to_apply" == "false" ]] && return;

    if [ "$TERRAFORM_EXTERNAL_APPLY_CONFIRMATIONS_REQUIRED" == "true" ]; then
        terraform_request_apply_confirmations;
    else

        echo
        echo ===============
        read -p "Press enter to apply this plan
===============";

        terraform_apply;
    fi;
}
readonly -f terraform_plan_confirm_apply;

function terraform_plan_destroy_confirm_apply() {
    local changes_to_apply="false";
    export TERRAFORM_ACTION="DESTROY";

    terraform_plan --destroy "true";
    [[ "$changes_to_apply" == "false" ]] && return;

    if [ "$TERRAFORM_EXTERNAL_DESTROY_CONFIRMATIONS_REQUIRED" == "true" ]; then
        terraform_request_destroy_confirmations;
    else
        echo
        echo =============================================
        read -p "Enter the word 'DESTROY' to apply this DESTROY plan
=============================================
" answer;

        if [ "$answer" != "DESTROY" ]; then
            log_info "Answer was not 'DESTROY', try once more.";
            read -p "Enter the word 'DESTROY' to apply this DESTROY plan " answer;
            [[ "$answer" != "DESTROY" ]] && log_info "Answer was not 'DESTROY', aborting." && exit 1;
        fi;
        terraform_apply destroy="true";
    fi;
}
readonly -f terraform_plan_destroy_confirm_apply;


function dump_terraform_files() {
    echo
    for f in $(find . -maxdepth 1 -type f -name \*.tpl | sort); do
        echo "---- $f:";
        cat "$f";
    done;
    echo
    echo
    for f in $(find . -maxdepth 1 -type f -name \*.tf | sort); do
        echo "---- $f:";
        cat "$f";
    done;
    echo
    echo
    for f in $(find . -maxdepth 1 -type f -name \*.tfvars | sort); do
        echo "---- $f:";
        cat "$f";
    done;
}

function generate_vars_arguments() {
    vars_arguments="";
    log_info "Adding arguments for tfvars-files, if .tfvar-files exist under the packet.";
    for f in $(find . -maxdepth 1 -type f -name \*.tfvars | sort); do
        f="$(basename $f)";
        log_info "Adding vars-argument for file $f";
        vars_arguments=" $vars_arguments -var-file $f";
    done;
}

function terraform_refresh() {
    terraform_init;
    $TERRAFORM refresh -no-color;
}
readonly -f terraform_refresh;


function terraform_get_output() {
    local function_name="terraform_get_output" do_init="true" output_attribute_name;
    import_args "$@";
    [[ "$do_init" == "true" ]] && terraform_init;
    output="$($TERRAFORM output -json -no-color)";
    echo "============ BEGIN OUTPUT ===============";
    echo
    echo "$output"
    echo
    echo "============  END OUTPUT  ===============";
}

function save_last_output() {
    local function_name="save_last_output" output_json output_attribute_name;
    import_args "$@";
    check_required_arguments $function_name output_json output_attribute_name;
    #output_json="$(echo "$output_json" | jq -c '.')";
    update_instance_attribute --instance_id "$instance_db_id" --attribute_name "$output_attribute_name" --attribute_value "$output_json" --compile_instance="true";
}

function validate_terraform_sha_file() {
    log_info "A SHA-file exists for the plan. Validating it using arguments-file";
    local json_file="/tmp/infraxys/system/custom/arguments.json";
    if [ ! -f "$json_file" ]; then
        log_fatal "SHA-file for the plan exists, but $json_file is not there to validate the SHA.";
    fi;
    cat "$json_file";

    local sha="$(cat "$json_file" | jq -r '.sha' )";
    if [ "sha" == "null" ]; then
       log_fatal "Argument JSON doesn't contain attribute 'sha'!";
    fi;
    local file_sha="$(cat "${TERRAFORM_PLAN_FILE}.sha")";
    log_info "Comparing SHA $sha to $file_sha.";
    if [ "$sha" != "$file_sha" ]; then
        log_fatal "Plan file has changed or an invalid SHA was passed.";
    fi;
}
readonly -f validate_terraform_sha_file;

function terraform_import() {
    terraform_init;

    read -p "Enter resource type: " resource_type
    read -p "Enter resource name: " resource_name
    read -p "Enter resource to import object id: " resource_id

    [[ -z "$resource_type" || -z "$resource_name" || -z "$resource_id" ]] && log_fatal "Terraform resource type and name and the object id are mandatory.";
    echo $TERRAFORM import "$resource_type" "$resource_name";
    $TERRAFORM import "${resource_type}.$resource_name" "$resource_id";
}
readonly -f terraform_import

