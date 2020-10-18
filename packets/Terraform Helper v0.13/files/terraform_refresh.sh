#set ($generate_terraform_refresh = $instance.getAttribute("generate_terraform_refresh"))
#if ($generate_terraform_refresh == "" and $instance.parent)
#set ($generate_terraform_refresh = $instance.parent.getAttribute("generate_terraform_refresh", "1"))
#end

#if ($generate_terraform_refresh == 0)
	#set ($skip_file_creation = true)
	#stop
#end

cd "${D}TERRAFORM_TEMP_DIR";
terraform_refresh;
