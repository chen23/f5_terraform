# BIG-IP

# Create F5 BIG-IP VMs
module "bigip" {
  source                    = "github.com/f5devcentral/terraform-azure-bigip-module"
  dnsLabel                  = format("%s-%s", var.prefix, random_id.id.hex)
  resource_group_name       = azurerm_resource_group.rg.name
  mgmt_subnet_id            = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true }]
  mgmt_securitygroup_id     = [module.mgmt-network-security-group.network_security_group_id]
  external_subnet_id        = [{ "subnet_id" = data.azurerm_subnet.external-public.id, "public_ip" = true }]
  external_securitygroup_id = [module.external-network-security-group-public.network_security_group_id]
  internal_subnet_id        = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false }]
  internal_securitygroup_id = [module.internal-network-security-group.network_security_group_id]
  availabilityZones         = var.availabilityZones
  f5_username               = var.f5_username
  f5_instance_type          = var.f5_instance_type
  f5_image_name             = var.f5_image_name
  f5_version                = var.f5_version
  f5_product_name           = var.f5_product_name
}

# Create the Network Security group Module to associate with BIGIP-Mgmt-Nic
module "mgmt-network-security-group" {
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg.name
  security_group_name   = format("%s-mgmt-nsg-%s", var.prefix, random_id.id.hex)
  source_address_prefix = var.AllowedIPs

  custom_rules = [
    {
      name                   = "allow_https"
      priority               = "100"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      destination_port_range = "443"
    },
    {
      name                   = "allow_ssh"
      priority               = "101"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      destination_port_range = "22"
    }
  ]

  tags = {
    environment = var.environment
    costcenter  = var.costcenter
  }
}

# Create the Network Security group Module to associate with BIGIP-External-Nic
module "external-network-security-group-public" {
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg.name
  security_group_name   = format("%s-external-public-nsg-%s", var.prefix, random_id.id.hex)
  source_address_prefix = var.AllowedIPs

  custom_rules = [
    {
      name                   = "allow_http"
      priority               = "100"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      destination_port_range = "80"
    },
    {
      name                   = "allow_https"
      priority               = "101"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      destination_port_range = "443"
    },
    {
      name                   = "allow_8443"
      priority               = "102"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      destination_port_range = "8443"
    },
    {
      name                   = "allow_ssh"
      priority               = "103"
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "tcp"
      destination_port_range = "22"
    }
  ]

  tags = {
    environment = var.environment
    costcenter  = var.costcenter
  }
}

# Create the Network Security group Module to associate with BIGIP-Internal-Nic
module "internal-network-security-group" {
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg.name
  security_group_name = format("%s-internal-nsg-%s", var.prefix, random_id.id.hex)
  tags = {
    environment = var.environment
    costcenter  = var.costcenter
  }
}

# Create AS3 declaration
data "template_file" "as3" {
  template = file("${path.module}/as3.json.tpl")

  vars = {
    rg_name         = azurerm_resource_group.rg.name
    subscription_id = var.sp_subscription_id
    tenant_id       = var.sp_tenant_id
    client_id       = var.sp_client_id
    client_secret   = var.sp_client_secret
    publicvip       = var.f5publicvip
    privatevip      = var.f5privatevip
  }
}

# Create TS declaration
data "template_file" "ts" {
  template = file("${path.module}/ts.json.tpl")

  vars = {
    region      = var.location
    law_id      = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey = azurerm_log_analytics_workspace.law.primary_shared_key
  }
}

# Run REST API for configuration
resource "local_file" "as3_json" {
  content  = data.template_file.as3.rendered
  filename = "${path.module}/as3.json"
}

resource "local_file" "ts_json" {
  content  = data.template_file.ts.rendered
  filename = "${path.module}/ts.json"
}

# resource "null_resource" "f5vm01_DO" {
#   depends_on = [module.bigip]
#   # Running DO REST API
#   provisioner "local-exec" {
#     command = <<-EOF
#       #!/bin/bash
#       curl -k -X ${var.rest_do_method} https://${azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm01_do_file}
#       x=1; while [ $x -le 30 ]; do STATUS=$(curl -s -k -X GET https://${azurerm_public_ip.vm01mgmtpip.ip_address}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
#       sleep 10
#     EOF
#   }
# }

# resource "null_resource" "f5vm01_TS" {
#   depends_on = [null_resource.f5vm01_DO]
#   # Running TS REST API
#   provisioner "local-exec" {
#     command = <<-EOF
#       #!/bin/bash
#       curl -H 'Content-Type: application/json' -k -X POST https://${azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_ts_file}
#     EOF
#   }
# }

# resource "null_resource" "f5vm_AS3" {
#   depends_on = [null_resource.f5vm01_TS]
#   # Running AS3 REST API
#   provisioner "local-exec" {
#     command = <<-EOF
#       #!/bin/bash
#       curl -k -X ${var.rest_as3_method} https://${azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_as3_file}
#     EOF
#   }
# }
