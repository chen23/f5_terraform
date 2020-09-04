# Variables

# REST API Setting
variable rest_do_uri { default = "/mgmt/shared/declarative-onboarding" }
variable rest_as3_uri { default = "/mgmt/shared/appsvcs/declare" }
variable rest_do_method { default = "POST" }
variable rest_as3_method { default = "POST" }
variable rest_ts_uri { default = "/mgmt/shared/telemetry/declare" }

# Azure Environment
variable sp_subscription_id {}
variable sp_client_id {}
variable sp_client_secret {}
variable sp_tenant_id {}
variable prefix {}
variable location {}

# NETWORK
variable AllowedIPs {}
variable cidr { default = "10.90.0.0/16" }
variable f5privatevip { default = "10.90.2.111" }
variable f5publicvip { default = "10.90.2.112" }
variable mgmt_gw { default = "10.90.1.1" }
variable ext_gw { default = "10.90.2.1" }

variable availabilityZones {
  description = "If you want the VM placed in an Azure Availability Zone, and the Azure region you are deploying to supports it, specify the numbers of the existing Availability Zone you want to use."
  type        = list
  default     = [1]
}

# BIGIP Image
variable f5_instance_type { default = "Standard_DS4_v2" }
variable f5_image_name { default = "f5-bigip-virtual-edition-25m-best-hourly" }
variable f5_product_name { default = "f5-big-ip-best" }
variable f5_version { default = "15.1.004000" }

# BIGIP Setup
variable f5_username {}
variable azure_keyvault_secret_name {}
variable license1 { default = "" }
variable doPackageUrl { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.15.0/f5-declarative-onboarding-1.15.0-3.noarch.rpm" }
variable as3PackageUrl { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.22.0/f5-appsvcs-3.22.0-2.noarch.rpm" }
variable tsPackageUrl { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.14.0/f5-telemetry-1.14.0-2.noarch.rpm" }
variable libs_dir { default = "/config/cloud/azure/node_modules" }
variable onboard_log { default = "/var/log/startup-script.log" }

# TAGS
variable environment { default = "dev" } #ex. dev/staging/prod
variable costcenter { default = "terraform" }
