#set ($generate_terraform_show_files = $instance.getAttribute("generate_terraform_show_files"))
#if ($generate_terraform_show_files == "" and $instance.parent)
#set ($generate_terraform_show_files = $instance.parent.getAttribute("generate_terraform_show_files", "1"))
#end

#if ($generate_terraform_show_files == 0)
	#set ($skip_file_creation = true)
	#stop
#end

cd "${D}TERRAFORM_TEMP_DIR";
dump_terraform_files;
