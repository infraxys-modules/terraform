TERRAFORM_TEMP_DIR="/tmp/terraform";
export TF_VAR_TERRAFORM_TEMP_DIR="${D}TERRAFORM_TEMP_DIR"
mkdir -p "${D}TERRAFORM_TEMP_DIR";
cp -R . "${D}TERRAFORM_TEMP_DIR";
#foreach ($terraformInstance in $instance.getInstancesByFileExtensions(".tf", ".tpl", ".tfvars"))
dir="$terraformInstance.getRelativePath()";
cd ../../../${D}dir;
if [ -f "init.sh" ]; then
    log_info "Sourcing init.sh in ${D}dir";
    . ./init.sh;
fi;
log_info 'Copying .tf, .tpl and .tfvars files from instance "$terraformInstance.toString()"';
tmp_instance_id="$terraformInstance.getId()";
#[[
for f in $(find . -maxdepth 1 -type f -name \*.tf); do
    f="$(basename "$f")" # remove ./
    log_info "Copying $f as '$TERRAFORM_TEMP_DIR/${tmp_instance_id}_$f'.";
    cp $f "$TERRAFORM_TEMP_DIR/${tmp_instance_id}_$f";
done;

for f in $(find . -maxdepth 1 -type f -name \*.tpl); do
    f="$(basename "$f")" # remove ./
    log_info "Copying $f from ../../../$dir";
    cp $f "$TERRAFORM_TEMP_DIR";
done;

for f in $(find . -maxdepth 1 -type f -name \*.tfvars); do
    f="$(basename "$f")" # remove ./
    log_info "Copying $f from ../../../$dir";
    cp $f "$TERRAFORM_TEMP_DIR";
done;
]]#
#end