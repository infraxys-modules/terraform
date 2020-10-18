#set ($generate_terraform_show_output = $instance.getAttribute("generate_terraform_show_output"))
#if ($generate_terraform_show_output == "" and $instance.parent)
#set ($generate_terraform_show_output = $instance.parent.getAttribute("generate_terraform_show_output", "1"))
#end

#if ($generate_terraform_show_output == 0)
	#set ($skip_file_creation = true)
	#stop
#end

cd "${D}TERRAFORM_TEMP_DIR";
terraform_get_output;
