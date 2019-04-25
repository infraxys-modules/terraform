TERRAFORM_TEMP_DIR="/tmp/terraform";
mkdir -p "${D}TERRAFORM_TEMP_DIR";
cp -R . "${D}TERRAFORM_TEMP_DIR";

#foreach ($terraformInstance in $instance.getInstancesByFileExtension(".tf"))
dir="$terraformInstance.getRelativePath()";

cd ../../../${D}dir;
if [ -f "init.sh" ]; then
    log_info "Sourcing init.sh in ${D}dir";
    . ./init.sh;
fi;

log_info 'Copying .tf and .tpl files from "$terraformInstance.toString()"';
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
]]#
#end
