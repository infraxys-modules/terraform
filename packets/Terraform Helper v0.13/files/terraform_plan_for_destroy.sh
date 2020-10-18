#set ($generate_terraform_plan_for_destroy = $instance.getAttribute("generate_terraform_plan_for_destroy"))
#if ($generate_terraform_plan_for_destroy == "" and $instance.parent)
#set ($generate_terraform_plan_for_destroy = $instance.parent.getAttribute("generate_terraform_plan_for_destroy", "1"))
#end

#if ($generate_terraform_plan_for_destroy == 0)
	#set ($skip_file_creation = true)
	#stop
#end
#set ($menu_caption = $instance.getAttribute("plan_for_destroy_menu_caption"))

cd "${D}TERRAFORM_TEMP_DIR";
terraform_plan --destroy "true";
