#set ($generate_terraform_import = $instance.getAttribute("generate_terraform_import"))
#if ($generate_terraform_import == "" and $instance.parent)
#set ($generate_terraform_import = $instance.parent.getAttribute("generate_terraform_import", "1"))
#end

#if ($generate_terraform_import == 0)
	#set ($skip_file_creation = true)
	#stop
#end

cd "${D}TERRAFORM_TEMP_DIR";
terraform_import;



