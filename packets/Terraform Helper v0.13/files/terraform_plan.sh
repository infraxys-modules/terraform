#set ($generate_terraform_plan = $instance.getAttribute("generate_terraform_plan"))
#if ($generate_terraform_plan == "" and $instance.parent)
#set ($generate_terraform_plan = $instance.parent.getAttribute("generate_terraform_plan", "1"))
#end

#if ($generate_terraform_plan == 0)
	#set ($skip_file_creation = true)
	#stop
#end
#set ($menu_caption = $instance.getAttribute("plan_menu_caption"))

cd "${D}TERRAFORM_TEMP_DIR";
terraform_plan;
