
function ensure_opa() {
  local function_name="ensure_opa" opa_version="v0.16.1";
  export OPA="/usr/local/bin/opa-$opa_version";
  if [ -f "$filename" ]; then
    log_info "Using OPA version $opa_version.";
  else
    log_info "Installing OPA version $opa_version";
    curl -sSLo "$OPA" https://github.com/open-policy-agent/opa/releases/download/${opa_version}/opa_linux_amd64;
    chmod u+x "$OPA";
  fi;
}
readonly -f ensure_opa;

function execute_rego_validators() {
  local function_name="execute_rego_validators" plan_file fails="false" terraform_plan_json_file="/tmp/plan.json" \
        json_created="false" opa_tests_ok="true";
  import_args "$@";
  check_required_arguments $function_name plan_file;

  log_info "Executing rego validators (files in the instance directory and at the environment-level with names starting with 'rego_validator'."

  for validator in $(find "$INSTANCE_DIR/" "$INFRAXYS_ROOT/environments/$environment_directory/environment.auto/" -type f -name rego_validator\*); do

    if [ "$json_created" == "false" ]; then
      ensure_opa;
      log_info "Converting the Terraform plan to JSON for OPA."
      terraform show -json "$plan_file" > "$terraform_plan_json_file";
      json_created="true";
    fi;

    log_info "Executing $validator";
    set +e;

    # run in a subshell and avoid that the shell can change our environment
    (. $validator --terraform_plan_json_file "$terraform_plan_json_file");
    local exit_code=$?
    [[ "$exit_code" -ne 0 ]] && log_error "Test failed with exit code $exit_code" && opa_tests_ok="false";
    set -e;
  done;
  if [ "$opa_tests_ok" != "true" ]; then
    log_error "OPA tests violated, aborting!";
    exit 1;
  fi;

}
readonly -f execute_rego_validators;