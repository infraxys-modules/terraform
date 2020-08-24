log_info "Ensuring that the following versions of Terraform are installed:
$versions";

for version in $versions; do
	[[ -n "$version" ]] && ensure_terraform --terraform_version "$version";
done;

log_info "Installation complete";