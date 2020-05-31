DEFAULT_TERRAFORM_VERSION="0.12.12";
process_netrc_variables; # make sure https-modules that are in GitHub Enterprise and/or private can be downloaded

function terraform_init() {
    if [ -z "$terraform_version" ]; then
        log_info "Terraform version not specified. Using version $DEFAULT_TERRAFORM_VERSION";
        local terraform_version="$DEFAULT_TERRAFORM_VERSION";
    fi;

    export TERRAFORM="/usr/local/bin/terraform-$terraform_version";
    if [ -f "$TERRAFORM" ]; then
        log_info "Using Terraform version $terraform_version"
    else
        log_info "Terraform version $terraform_version not available in this provisioning server Docker image. Installing it now.";
        mkdir /tmp/install_terraform
        curl -sL -o /tmp/install_terraform/terraform.zip https://releases.hashicorp.com/terraform/${terraform_version}/terraform_${terraform_version}_linux_amd64.zip;
        cd /tmp/install_terraform;
        unzip terraform.zip;
        mv terraform $TERRAFORM;
        rm -Rf /tmp/install_terraform
        cd -;
    fi;
    $TERRAFORM init -no-color;
}
readonly -f terraform_init;

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

function terraform_plan_confirm_apply() {
  local plan_file="/tmp/plan.out";
  local rego_file="$INSTANCE_DIR/terraform.rego";
  terraform_init;
  set +e; # exit code 2 indicates changes should be applied
  $TERRAFORM plan -no-color -detailed-exitcode -out="$plan_file";
  local plan_result="$?"
  [[ "$plan_result" == "0" ]] && log_info "No changes to apply" && return;
  [[ "$plan_result" == "1" ]] && log_error "Errors detected during Terraform plan." && exit 1 && return;
  set -e;
  execute_rego_validators --plan_file "$plan_file"

  echo
  echo ===============
  read -p "Press enter to apply this plan
===============";


  terraform_apply --plan_file "$plan_file";

}
readonly -f terraform_plan_confirm_apply;

function terraform_plan() {
    terraform_init;
    $TERRAFORM plan -no-color;
}
readonly -f terraform_plan;

function terraform_refresh() {
    terraform_init;
    $TERRAFORM refresh -no-color;
}
readonly -f terraform_plan;

function terraform_plan_destroy_confirm_apply() {
  local plan_file="/tmp/plan.out";
  terraform_init;
  set +e; # exit code 2 indicates changes should be applied
  $TERRAFORM plan -destroy -no-color -detailed-exitcode -out="$plan_file";
  local plan_result="$?"
  [[ "$plan_result" == "0" ]] && log_info "No changes to apply" && return;
  [[ "$plan_result" == "1" ]] && log_error "Errors detected during Terraform plan." && exit 1 && return;
  set -e;
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
  terraform_apply --plan_file "$plan_file";
}
readonly -f terraform_plan_destroy_confirm_apply;

function terraform_plan_destroy() {
    terraform_init;
    $TERRAFORM plan -destroy -no-color;
}
readonly -f terraform_plan_destroy;

function terraform_apply() {
    local grant output_attribute_name="" plan_file="";
    import_args "$@";
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
    if [ -z "$plan_file" ]; then
      terraform_init;
      log_info "Executing $TERRAFORM apply";
      $TERRAFORM apply -no-color -auto-approve;
    else
      log_info "Applying the plan";
      $TERRAFORM apply -no-color "$plan_file";
    fi;
    log_info "Apply done";
    if [ "$?" != "0" ]; then
        log_error "Terraform failed. Aborting.";
        exit 1;
    fi;
    if [ -n "$output_attribute_name" ]; then
      terraform_get_output --do_init "false" --output_attribute_name "$output_attribute_name";
    fi;
    run_or_source_files --directory "$INSTANCE_DIR" --filename_pattern 'after_terraform_apply*';
}
readonly -f terraform_apply;

function terraform_destroy() {
    local output_attribute_name="";
    import_args "$@";
    terraform_init;
    $TERRAFORM destroy -force -no-color;
    if [ "$?" != "0" ]; then
        log_error "Terraform failed. Aborting.";
        exit 1;
    fi;
    if [ -n "$output_attribute_name" ]; then
      terraform_get_output --do_init="false" --output_attribute_name "$output_attribute_name";
    fi;
    run_or_source_files --directory "$INSTANCE_DIR" --filename_pattern 'after_terraform_destroy*';
}
readonly -f terraform_destroy;

function terraform_get_output() {
    local function_name="terraform_get_output" do_init="true" output_attribute_name;
    import_args "$@";
    check_required_arguments $function_name output_attribute_name
    [[ "$do_init" == "true" ]] && terraform_init;
    output="$($TERRAFORM output -json -no-color)";
    save_last_output --output_json "$output" --output_attribute_name "$output_attribute_name";
}

function save_last_output() {
    local function_name="save_last_output" output_json output_attribute_name;
    import_args "$@";
    check_required_arguments $function_name output_json output_attribute_name;
    #output_json="$(echo "$output_json" | jq -c '.')";
    update_instance_attribute --instance_id "$instance_db_id" --attribute_name "$output_attribute_name" --attribute_value "$output_json" --compile_instance="true";
}
