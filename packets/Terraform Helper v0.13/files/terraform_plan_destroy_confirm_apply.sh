#set ($generate_terraform_plan_for_destroy_confirm_apply = $instance.getAttribute("generate_terraform_plan_for_destroy_confirm_apply"))
#if ($generate_terraform_plan_for_destroy_confirm_apply == "" and $instance.parent)
#set ($generate_terraform_plan_for_destroy_confirm_apply = $instance.parent.getAttribute("generate_terraform_plan_for_destroy_confirm_apply", "1"))
#end

#if ($generate_terraform_plan_for_destroy_confirm_apply == 0)
	#set ($skip_file_creation = true)
	#stop
#end
#set ($menu_caption = $instance.getAttribute("plan_for_destroy_confirm_apply_menu_caption"))

cd "${D}TERRAFORM_TEMP_DIR";
terraform_plan_destroy_confirm_apply;
