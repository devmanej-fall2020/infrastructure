# Terraform - Infrastructure as Code

Terraform is the infrastructure as code tool from HashiCorp. It is a tool for building, changing, and managing infrastructure in a safe, repeatable way. Operators and Infrastructure teams can use Terraform to manage environments with a configuration language called the HashiCorp Configuration Language (HCL) for human-readable, automated deployments.

##Prerequisites:##
1. Cloud Provider - In this case, AWS
2. CLI access setup for above account
2. Terraform installed on local machine

##Steps:##
**The basic workflow steps of a Terraform deployment is as follows:**
    1. **Scope** - Confirm what resources need to be created for a given project.
    2. **Author** - Create the configuration file in HCL based on the scoped parameters
    3. **Initialize** - Run terraform init in the project directory with the configuration files. This will download the correct provider plug-ins for the project.
    4. **Plan & Apply** - Run terraform plan to verify creation process and then terraform apply to create real resources as well as state file that compares future changes in your configuration files to what actually exists in your deployment environment. Upon terraform apply, the user will be prompted to review the proposed changes and must affirm the changes or else Terraform will not apply the proposed plan.
    5. **Destroy** - The terraform destroy command terminates resources defined in your Terraform configuration. This command is the reverse of terraform apply in that it terminates all the resources specified by the configuration. It does not destroy resources running elsewhere that are not described in the current configuration.Just like with apply, Terraform determines the order in which things must be destroyed.





