# Infraxys module - Terraform

This module provides a framework to integrate Terraform in other modules.  

## OPA - Open Policy Agent

Files with a name that starts with 'rego_validator' in both the instance- and environment-directories are run automatically before applying a plan.

These files can run OPA against a Terraform plan with local rego-files and/or policies that come from somewhere else like a REST-endpoint, git-repo, ...  
The action is cancelled if the exit-code is non-zero.

Enforce policies in environments under project trees:
- Create a container and add one or more packets that contain files with a name starting with 'rego_validor' (ex.: rego_validator_required_team_membership.go, rego_validator_only_on_a_schedule.py)
- Specify "Environment"-level for the scope of the file (Save with). This ensures the file will be available in any environment where the container is shared.
- Share the container with other projects through the 'Included containers'-tab of those projects. Make sure "Allow overrides" is disabled to enforce that the script will be run before every apply in the whole project-tree.

### current_user.json
 
This read-only file is always available as /tmp/infraxys/system/current_user.json and contains besides the username all teams, grants and projects of the account. 

Use this information to enforce fine-grained access control with information in Infraxys itself, or using external services like GitHub or Okta (require specific Okta-team membership, for example). 

Environment-level files, as specified above, are run before the action itself is started.  
This means that current_user.json can also be used without OPA. 

## Usage

### Create a packet

Create a packet with one or more files with extension "tf" and "tpl".  
Inherit the files of the "Terraform Helper" packet by adding the following line to the "Inherit files"-field:   
```github.com\infraxys-modules\terraform\master\terraform helper```  

Instances of this packet that are created in the sub-tree of another instance that has attribute "skip_terraform_action_creation" with value "1" (checked), then no actions will be created and the Terraform files of these instances will be managed by a higher level parent (which should also inherit the Terraform Helper files).

Other instances will have the Terraform plan and apply actions outlined below.

### Retrieve information before Terraform run

If you need to gather information just before executing Terraform, then create a file called "init.sh" to do so.

 
## Inherited files:

__after_modules_enabled_01_terraform_setup.sh__

This script gathers all .tf- and .tpl-files under the instance-tree and executes init.sh-scripts if they exist.

__check_action_creation.sh__

When this script is generated through Apache Velocity, it checks if there is a parent that has attribute "skip_terraform_action_creation" with value "1".  
If it finds such attribute, no actions will be created for this instance.

__terraform_apply.sh__

Runs apply without user confirmation.

__terraform_destroy.sh__ 

Runs destroy without user confirmation.

__terraform_plan.sh__

Runs and outputs terraform plan only.

__terraform_plan_confirm_apply.sh__ 

Runs and outputs terraform plan, asks the user to press enter before executing apply.

__terraform_plan_destroy.sh__

Runs and outputs terraform destroy plan only.

__terraform_plan_destroy_confirm_apply.sh__ 

Runs and outputs terraform destroy plan, asks the user to enter "DESTROY" before executing apply destroy.


