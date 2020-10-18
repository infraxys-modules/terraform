#set ($generate_terraform_destroy = $instance.getAttribute("generate_terraform_destroy"))
#if ($generate_terraform_destroy == "" and $instance.parent)
#set ($generate_terraform_destroy = $instance.parent.getAttribute("generate_terraform_destroy", "1"))
#end

#if ($generate_terraform_destroy == 0)
	#set ($skip_file_creation = true)
	#stop
#end
#set ($menu_caption = $instance.getAttribute("destroy_menu_caption"))

cd "${D}TERRAFORM_TEMP_DIR";
terraform_apply --destroy "true";
