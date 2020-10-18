#set ($generate_terraform_apply = $instance.getAttribute("generate_terraform_apply"))
#if ($generate_terraform_apply == "" and $instance.parent)
#set ($generate_terraform_apply = $instance.parent.getAttribute("generate_terraform_apply", "1"))
#end

#if ($generate_terraform_apply == 0)
	#set ($skip_file_creation = true)
	#stop
#end
#set ($menu_caption = $instance.getAttribute("apply_menu_caption"))

cd "${D}TERRAFORM_TEMP_DIR";
terraform_apply;
