
terraform {
  required_providers {
    azurerm = {
      source  = "azurerm"
      version = "4.33.0"
    }
  }
}
provider "azurerm" {
  features {}
}

#creation of Resource group

resource "azurerm_resource_group" "rg_dev" {
  location   = var.LOCATION
  managed_by = ""
  name       = var.RG_NAME
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
}

#creation of ADF resource

resource "azurerm_data_factory" "adf_dev" {
  customer_managed_key_id          = ""
  customer_managed_key_identity_id = ""
  location                         = "westeurope"
  managed_virtual_network_enabled  = true
  name                             = var.ADF_NAME
  public_network_enabled           = false
  purview_id                       = ""
  resource_group_name              = azurerm_resource_group.rg_dev.name
  tags = {
    "Support Contact" = "Vijay Ganji"
  }
  identity {
    identity_ids = []
    type         = "SystemAssigned"
  }
}

#creation of ADF Autoresolve IR ( NOTE: For On-Prem SQL Server connection we need self hosted IR)

resource "azurerm_data_factory_integration_runtime_azure" "adf_autoir" {
  cleanup_enabled         = false
  compute_type            = "General"
  core_count              = 8
  data_factory_id         = azurerm_data_factory.adf_dev.id
  description             = ""
  location                = "autoresolve"
  name                    = "AutoResolveIntegrationRuntime"
  time_to_live_min        = 0
  virtual_network_enabled = true
}

#creation of Azure Data bricks resource

resource "azurerm_databricks_workspace" "adb_dev" {
  customer_managed_key_enabled                        = false
  infrastructure_encryption_enabled                   = true
  load_balancer_backend_address_pool_id               = ""
  location                                            = "westeurope"
  managed_disk_cmk_key_vault_id                       = ""
  managed_disk_cmk_key_vault_key_id                   = ""
  managed_disk_cmk_rotation_to_latest_version_enabled = false
  managed_resource_group_name                         = "MRG"
  managed_services_cmk_key_vault_id                   = ""
  managed_services_cmk_key_vault_key_id               = ""
  name                                                = var.ADB_NAME
  public_network_access_enabled                       = true
  resource_group_name                                 = azurerm_resource_group.rg_dev.name
  sku                                                 = "premium"
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
  custom_parameters {
    machine_learning_workspace_id                        = ""
    nat_gateway_name                                     = ""
    no_public_ip                                         = true
    private_subnet_name                                  = "Private-ADB"
    private_subnet_network_security_group_association_id = ""
    public_ip_name                                       = ""
    public_subnet_name                                   = "Public-ADB"
    public_subnet_network_security_group_association_id  = ""
    storage_account_name                                 = "dbstorageohu5pvmp7vgau"
    storage_account_sku_name                             = "Standard_GRS"
    virtual_network_id                                   = azurerm_virtual_network.res-36.id
    vnet_address_prefix                                  = ""
  }
  enhanced_security_compliance {
    automatic_cluster_update_enabled      = false
    compliance_security_profile_enabled   = false
    compliance_security_profile_standards = []
    enhanced_security_monitoring_enabled  = true
  }
}

#Azure key vault creation to store (SQL Credentials or ADF PAT)

resource "azurerm_key_vault" "akv_dev" {
  access_policy                   = []
  enable_rbac_authorization       = true
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  location                        = var.LOCATION
  name                            = var.AKV_NAME
  public_network_access_enabled   = false
  purge_protection_enabled        = false
  resource_group_name             = azurerm_resource_group.rg_dev.name
  sku_name                        = "standard"
  soft_delete_retention_days      = 90
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
  tenant_id = ""
  network_acls {
    bypass                     = "None"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

#NSG for ADF

resource "azurerm_network_security_group" "adf_nsg_dev" {
  location            = var.LOCATION
  name                = "ADF-NSG"
  resource_group_name = azurerm_resource_group.rg_dev.name
  security_rule       = []
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
}

#Private endpoint for Azure storage account data lake

resource "azurerm_network_security_group" "res-12" {
  location            = "westeurope"
  name                = "PE-ASA-DL"
  resource_group_name = azurerm_resource_group.res-0.name
  security_rule       = []
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
}
resource "azurerm_network_security_group" "res-13" {
  location            = "westeurope"
  name                = "VLK-Private-NSG"
  resource_group_name = azurerm_resource_group.res-0.name
  security_rule       = []
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
}
resource "azurerm_network_security_group" "res-14" {
  location            = "westeurope"
  name                = "VLK-Public-NSG"
  resource_group_name = azurerm_resource_group.res-0.name
  security_rule       = []
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
}
resource "azurerm_network_security_group" "res-15" {
  location            = "westeurope"
  name                = "databricksnsg2i277hvdzhcaq"
  resource_group_name = azurerm_resource_group.res-0.name
  security_rule = [{
    access                                     = "Allow"
    description                                = "Required for worker communication with Azure Eventhub services."
    destination_address_prefix                 = "EventHub"
    destination_address_prefixes               = []
    destination_application_security_group_ids = []
    destination_port_range                     = "9093"
    destination_port_ranges                    = []
    direction                                  = "Outbound"
    name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub"
    priority                                   = 104
    protocol                                   = "Tcp"
    source_address_prefix                      = "VirtualNetwork"
    source_address_prefixes                    = []
    source_application_security_group_ids      = []
    source_port_range                          = "*"
    source_port_ranges                         = []
    }, {
    access                                     = "Allow"
    description                                = "Required for worker nodes communication within a cluster."
    destination_address_prefix                 = "VirtualNetwork"
    destination_address_prefixes               = []
    destination_application_security_group_ids = []
    destination_port_range                     = "*"
    destination_port_ranges                    = []
    direction                                  = "Inbound"
    name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound"
    priority                                   = 100
    protocol                                   = "*"
    source_address_prefix                      = "VirtualNetwork"
    source_address_prefixes                    = []
    source_application_security_group_ids      = []
    source_port_range                          = "*"
    source_port_ranges                         = []
    }, {
    access                                     = "Allow"
    description                                = "Required for worker nodes communication within a cluster."
    destination_address_prefix                 = "VirtualNetwork"
    destination_address_prefixes               = []
    destination_application_security_group_ids = []
    destination_port_range                     = "*"
    destination_port_ranges                    = []
    direction                                  = "Outbound"
    name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound"
    priority                                   = 100
    protocol                                   = "*"
    source_address_prefix                      = "VirtualNetwork"
    source_address_prefixes                    = []
    source_application_security_group_ids      = []
    source_port_range                          = "*"
    source_port_ranges                         = []
    }, {
    access                                     = "Allow"
    description                                = "Required for workers communication with Azure SQL services."
    destination_address_prefix                 = "Sql"
    destination_address_prefixes               = []
    destination_application_security_group_ids = []
    destination_port_range                     = "3306"
    destination_port_ranges                    = []
    direction                                  = "Outbound"
    name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql"
    priority                                   = 102
    protocol                                   = "Tcp"
    source_address_prefix                      = "VirtualNetwork"
    source_address_prefixes                    = []
    source_application_security_group_ids      = []
    source_port_range                          = "*"
    source_port_ranges                         = []
    }, {
    access                                     = "Allow"
    description                                = "Required for workers communication with Azure Storage services."
    destination_address_prefix                 = "Storage"
    destination_address_prefixes               = []
    destination_application_security_group_ids = []
    destination_port_range                     = "443"
    destination_port_ranges                    = []
    direction                                  = "Outbound"
    name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage"
    priority                                   = 103
    protocol                                   = "Tcp"
    source_address_prefix                      = "VirtualNetwork"
    source_address_prefixes                    = []
    source_application_security_group_ids      = []
    source_port_range                          = "*"
    source_port_ranges                         = []
    }, {
    access                                     = "Allow"
    description                                = "Required for workers communication with Databricks control plane."
    destination_address_prefix                 = "AzureDatabricks"
    destination_address_prefixes               = []
    destination_application_security_group_ids = []
    destination_port_range                     = ""
    destination_port_ranges                    = ["3306", "443", "8443-8451"]
    direction                                  = "Outbound"
    name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp"
    priority                                   = 101
    protocol                                   = "Tcp"
    source_address_prefix                      = "VirtualNetwork"
    source_address_prefixes                    = []
    source_application_security_group_ids      = []
    source_port_range                          = "*"
    source_port_ranges                         = []
  }]
  tags = {}
}
resource "azurerm_network_security_rule" "res-16" {
  access                                     = "Allow"
  description                                = "Required for workers communication with Databricks control plane."
  destination_address_prefix                 = "AzureDatabricks"
  destination_address_prefixes               = []
  destination_application_security_group_ids = []
  destination_port_range                     = ""
  destination_port_ranges                    = ["3306", "443", "8443-8451"]
  direction                                  = "Outbound"
  name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp"
  network_security_group_name                = "databricksnsg2i277hvdzhcaq"
  priority                                   = 101
  protocol                                   = "Tcp"
 Support Contact resource_group_name         = azurerm_resource_group.rg_dev.name
  source_address_prefix                      = "VirtualNetwork"
  source_address_prefixes                    = []
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = []
  depends_on = [
    azurerm_network_security_group.res-15,
  ]
}
resource "azurerm_network_security_rule" "res-17" {
  access                                     = "Allow"
  description                                = "Required for worker communication with Azure Eventhub services."
  destination_address_prefix                 = "EventHub"
  destination_address_prefixes               = []
  destination_application_security_group_ids = []
  destination_port_range                     = "9093"
  destination_port_ranges                    = []
  direction                                  = "Outbound"
  name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub"
  network_security_group_name                = "databricksnsg2i277hvdzhcaq"
  priority                                   = 104
  protocol                                   = "Tcp"
 Support Contact resource_group_name         = azurerm_resource_group.rg_dev.name
  source_address_prefix                      = "VirtualNetwork"
  source_address_prefixes                    = []
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = []
  depends_on = [
    azurerm_network_security_group.res-15,
  ]
}
resource "azurerm_network_security_rule" "res-18" {
  access                                     = "Allow"
  description                                = "Required for workers communication with Azure SQL services."
  destination_address_prefix                 = "Sql"
  destination_address_prefixes               = []
  destination_application_security_group_ids = []
  destination_port_range                     = "3306"
  destination_port_ranges                    = []
  direction                                  = "Outbound"
  name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql"
  network_security_group_name                = "databricksnsg2i277hvdzhcaq"
  priority                                   = 102
  protocol                                   = "Tcp"
 Support Contact resource_group_name         = azurerm_resource_group.rg_dev.name
  source_address_prefix                      = "VirtualNetwork"
  source_address_prefixes                    = []
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = []
  depends_on = [
    azurerm_network_security_group.res-15,
  ]
}
resource "azurerm_network_security_rule" "res-19" {
  access                                     = "Allow"
  description                                = "Required for workers communication with Azure Storage services."
  destination_address_prefix                 = "Storage"
  destination_address_prefixes               = []
  destination_application_security_group_ids = []
  destination_port_range                     = "443"
  destination_port_ranges                    = []
  direction                                  = "Outbound"
  name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage"
  network_security_group_name                = "databricksnsg2i277hvdzhcaq"
  priority                                   = 103
  protocol                                   = "Tcp"
 Support Contact resource_group_name         = azurerm_resource_group.rg_dev.name
  source_address_prefix                      = "VirtualNetwork"
  source_address_prefixes                    = []
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = []
  depends_on = [
    azurerm_network_security_group.res-15,
  ]
}
resource "azurerm_network_security_rule" "res-20" {
  access                                     = "Allow"
  description                                = "Required for worker nodes communication within a cluster."
  destination_address_prefix                 = "VirtualNetwork"
  destination_address_prefixes               = []
  destination_application_security_group_ids = []
  destination_port_range                     = "*"
  destination_port_ranges                    = []
  direction                                  = "Inbound"
  name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound"
  network_security_group_name                = "databricksnsg2i277hvdzhcaq"
  priority                                   = 100
  protocol                                   = "*"
 Support Contact resource_group_name         = azurerm_resource_group.rg_dev.name
  source_address_prefix                      = "VirtualNetwork"
  source_address_prefixes                    = []
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = []
  depends_on = [
    azurerm_network_security_group.res-15,
  ]
}
resource "azurerm_network_security_rule" "res-21" {
  access                                     = "Allow"
  description                                = "Required for worker nodes communication within a cluster."
  destination_address_prefix                 = "VirtualNetwork"
  destination_address_prefixes               = []
  destination_application_security_group_ids = []
  destination_port_range                     = "*"
  destination_port_ranges                    = []
  direction                                  = "Outbound"
  name                                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound"
  network_security_group_name                = "databricksnsg2i277hvdzhcaq"
  priority                                   = 100
  protocol                                   = "*"
 Support Contact resource_group_name         = azurerm_resource_group.rg_dev.name
  source_address_prefix                      = "VirtualNetwork"
  source_address_prefixes                    = []
  source_application_security_group_ids      = []
  source_port_range                          = "*"
  source_port_ranges                         = []
  depends_on = [
    azurerm_network_security_group.res-15,
  ]
}
resource "azurerm_private_dns_zone" "res-22" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = azurerm_resource_group.res-0.name
  tags                = {}
  soa_record {
    email        = "azureprivatedns-host.microsoft.com"
    expire_time  = 2419200
    minimum_ttl  = 10
    refresh_time = 3600
    retry_time   = 300
    tags         = {}
    ttl          = 3600
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "res-23" {
  name                  = "szfnwn6x5a6y4"
  private_dns_zone_name = "privatelink.azuredatabricks.net"
  registration_enabled  = false
  resource_group_name   = azurerm_resource_group.res-0.name
  tags                  = {}
  virtual_network_id    = azurerm_virtual_network.res-36.id
  depends_on = [
    azurerm_private_dns_zone.res-22,
  ]
}
resource "azurerm_private_dns_zone" "res-24" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.res-0.name
  tags                = {}
  soa_record {
    email        = "azureprivatedns-host.microsoft.com"
    expire_time  = 2419200
    minimum_ttl  = 10
    refresh_time = 3600
    retry_time   = 300
    tags         = {}
    ttl          = 3600
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "res-25" {
  name                  = "szfnwn6x5a6y4"
  private_dns_zone_name = "privatelink.blob.core.windows.net"
  registration_enabled  = false
  resource_group_name   = azurerm_resource_group.res-0.name
  tags                  = {}
  virtual_network_id    = azurerm_virtual_network.res-36.id
  depends_on = [
    azurerm_private_dns_zone.res-24,
  ]
}
resource "azurerm_private_dns_zone" "res-26" {
  name                = "privatelink.datafactory.azure.net"
  resource_group_name = azurerm_resource_group.res-0.name
  tags                = {}
  soa_record {
    email        = "azureprivatedns-host.microsoft.com"
    expire_time  = 2419200
    minimum_ttl  = 10
    refresh_time = 3600
    retry_time   = 300
    tags         = {}
    ttl          = 3600
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "res-27" {
  name                  = "gqo3b4iisi6rc"
  private_dns_zone_name = "privatelink.datafactory.azure.net"
  registration_enabled  = false
  resource_group_name   = azurerm_resource_group.res-0.name
  tags                  = {}
  virtual_network_id    = azurerm_virtual_network.res-36.id
  depends_on = [
    azurerm_private_dns_zone.res-26,
  ]
}
resource "azurerm_private_dns_zone" "res-28" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.res-0.name
  tags                = {}
  soa_record {
    email        = "azureprivatedns-host.microsoft.com"
    expire_time  = 2419200
    minimum_ttl  = 10
    refresh_time = 3600
    retry_time   = 300
    tags         = {}
    ttl          = 3600
  }
}
resource "azurerm_private_dns_zone_virtual_network_link" "res-29" {
  name                  = "szfnwn6x5a6y4"
  private_dns_zone_name = "privatelink.vaultcore.azure.net"
  registration_enabled  = false
  resource_group_name   = azurerm_resource_group.res-0.name
  tags                  = {}
  virtual_network_id    = azurerm_virtual_network.res-36.id
  depends_on = [
    azurerm_private_dns_zone.res-28,
  ]
}
resource "azurerm_private_endpoint" "res-30" {
  custom_network_interface_name = ""
  location                      = "westeurope"
  name                          = "PE-ADB"
  resource_group_name           = azurerm_resource_group.res-0.name
  subnet_id                     = azurerm_subnet.res-37.id
  tags                          = {}
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.res-22.id]
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "PE-ADB_81c93926-20b0-429c-8064-39a98b4d30c9"
    private_connection_resource_alias = ""
    private_connection_resource_id    = "/subscriptions/dev-sub/resourcegroups/RG-VLK/providers/Microsoft.Databricks/workspaces/VLK-ADB"
    request_message                   = ""
    subresource_names                 = ["databricks_ui_api"]
  }
}
resource "azurerm_private_endpoint" "res-32" {
  custom_network_interface_name = ""
  location                      = "westeurope"
  name                          = "PE-AKV"
  resource_group_name           = azurerm_resource_group.res-0.name
  subnet_id                     = azurerm_subnet.res-40.id
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "PE-AKV_81c93926-20b0-429c-8064-39a98b4d30df"
    private_connection_resource_alias = ""
    private_connection_resource_id    = azurerm_key_vault.res-7.id
    request_message                   = ""
    subresource_names                 = ["vault"]
  }
}
resource "azurerm_private_endpoint" "res-33" {
  custom_network_interface_name = ""
  location                      = "westeurope"
  name                          = "PE-ASA-DL"
  resource_group_name           = azurerm_resource_group.res-0.name
  subnet_id                     = "/subscriptions/dev-sub/resourceGroups/RG-VLK/providers/Microsoft.Network/virtualNetworks/VLK-VNet/subnets/PE-ASA-DL"
  tags = {
    "Support Contact" = "Vijay Ganji"
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "PE-ASA-DL_81c93926-20b0-429c-8064-39a98b4d30f4"
    private_connection_resource_alias = ""
    private_connection_resource_id    = "/subscriptions/dev-sub/resourcegroups/RG-VLK/providers/Microsoft.Storage/storageAccounts/vlkasa"
    request_message                   = ""
    subresource_names                 = ["blob"]
  }
  depends_on = [
    # One of azurerm_subnet.res-41,azurerm_subnet_network_security_group_association.res-42 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_private_endpoint" "res-34" {
  custom_network_interface_name = ""
  location                      = "westeurope"
  name                          = "PE-VLK-ADF"
  resource_group_name           = azurerm_resource_group.res-0.name
  subnet_id                     = "/subscriptions/dev-sub/resourceGroups/RG-VLK/providers/Microsoft.Network/virtualNetworks/VLK-VNet/subnets/PE-ADF"
  tags                          = {}
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = ["/subscriptions/dev-sub/resourcegroups/RG-VLK/providers/Microsoft.Network/privateDnsZones/privatelink.datafactory.azure.net"]
  }
  private_service_connection {
    is_manual_connection              = false
    name                              = "PE-VLK-ADF"
    private_connection_resource_alias = ""
    private_connection_resource_id    = "/subscriptions/dev-sub/resourcegroups/RG-VLK/providers/Microsoft.DataFactory/factories/VLK-ADF"
    request_message                   = ""
    subresource_names                 = ["dataFactory"]
  }
  depends_on = [
    # One of azurerm_subnet.res-38,azurerm_subnet_network_security_group_association.res-39 (can't auto-resolve as their ids are identical)
  ]
}
resource "azurerm_virtual_network" "res-36" {
  address_space                  = ["10.0.1.0/24"]
  bgp_community                  = ""
  dns_servers                    = []
  edge_zone                      = ""
  flow_timeout_in_minutes        = 0
  location                       = "westeurope"
  name                           = "VLK-VNet"
  private_endpoint_vnet_policies = "Disabled"
  resource_group_name            = azurerm_resource_group.res-0.name
  subnet = [{
    address_prefixes                              = ["10.0.1.104/29"]
    default_outbound_access_enabled               = false
    delegation                                    = []
    id                                            = azurerm_subnet_network_security_group_association.res-39.id
    name                                          = "PE-ADF"
    private_endpoint_network_policies             = "Disabled"
    private_link_service_network_policies_enabled = true
    route_table_id                                = ""
    security_group                                = azurerm_network_security_group.res-11.id
    service_endpoint_policy_ids                   = []
    service_endpoints                             = []
    }, {
    address_prefixes                              = ["10.0.1.32/28"]
    default_outbound_access_enabled               = false
    delegation                                    = []
    id                                            = "/subscriptions/dev-sub/resourceGroups/RG-VLK/providers/Microsoft.Network/virtualNetworks/VLK-VNet/subnets/PE-AKV"
    name                                          = "PE-AKV"
    private_endpoint_network_policies             = "Disabled"
    private_link_service_network_policies_enabled = true
    route_table_id                                = ""
    security_group                                = ""
    service_endpoint_policy_ids                   = []
    service_endpoints                             = []
    }, {
    address_prefixes                              = ["10.0.1.48/28"]
    default_outbound_access_enabled               = false
    delegation                                    = []
    id                                            = "/subscriptions/dev-sub/resourceGroups/RG-VLK/providers/Microsoft.Network/virtualNetworks/VLK-VNet/subnets/PE-ADB"
    name                                          = "PE-ADB"
    private_endpoint_network_policies             = "Disabled"
    private_link_service_network_policies_enabled = true
    route_table_id                                = ""
    security_group                                = ""
    service_endpoint_policy_ids                   = []
    service_endpoints                             = []
    }, {
    address_prefixes                = ["10.0.1.64/28"]
    default_outbound_access_enabled = false
    delegation = [{
      name = "databricks-del-wkehkby3rdx3g"
      service_delegation = [{
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
        name    = "Microsoft.Databricks/workspaces"
      }]
    }]
    id                                            = azurerm_subnet_network_security_group_association.res-44.id
    name                                          = "Private-ADB"
    private_endpoint_network_policies             = "Disabled"
    private_link_service_network_policies_enabled = true
    route_table_id                                = ""
    security_group                                = azurerm_network_security_group.res-15.id
    service_endpoint_policy_ids                   = []
    service_endpoints                             = []
    }, {
    address_prefixes                = ["10.0.1.80/28"]
    default_outbound_access_enabled = false
    delegation = [{
      name = "databricks-del-wkehkby3rdx3g"
      service_delegation = [{
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
        name    = "Microsoft.Databricks/workspaces"
      }]
    }]
    id                                            = azurerm_subnet_network_security_group_association.res-46.id
    name                                          = "Public-ADB"
    private_endpoint_network_policies             = "Disabled"
    private_link_service_network_policies_enabled = true
    route_table_id                                = ""
    security_group                                = azurerm_network_security_group.res-15.id
    service_endpoint_policy_ids                   = []
    service_endpoints                             = []
    }, {
    address_prefixes                              = ["10.0.1.96/29"]
    default_outbound_access_enabled               = false
    delegation                                    = []
    id                                            = azurerm_subnet_network_security_group_association.res-42.id
    name                                          = "PE-ASA-DL"
    private_endpoint_network_policies             = "Disabled"
    private_link_service_network_policies_enabled = true
    route_table_id                                = ""
    security_group                                = azurerm_network_security_group.res-12.id
    service_endpoint_policy_ids                   = []
    service_endpoints                             = []
  }]
  tags = {
    "Support Contact" = "Vijay Ganji "
  }
}
resource "azurerm_subnet" "res-37" {
  address_prefixes                              = ["10.0.1.48/28"]
  default_outbound_access_enabled               = true
  name                                          = "PE-ADB"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = azurerm_resource_group.res-0.name
  service_endpoint_policy_ids                   = []
  service_endpoints                             = []
  virtual_network_name                          = "VLK-VNet"
  depends_on = [
    azurerm_virtual_network.res-36,
  ]
}
resource "azurerm_subnet" "res-38" {
  address_prefixes                              = ["10.0.1.104/29"]
  default_outbound_access_enabled               = true
  name                                          = "PE-ADF"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = azurerm_resource_group.res-0.name
  service_endpoint_policy_ids                   = []
  service_endpoints                             = []
  virtual_network_name                          = "VLK-VNet"
  depends_on = [
    azurerm_virtual_network.res-36,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-39" {
  network_security_group_id = azurerm_network_security_group.res-11.id
  subnet_id                 = azurerm_subnet.res-38.id
}
resource "azurerm_subnet" "res-40" {
  address_prefixes                              = ["10.0.1.32/28"]
  default_outbound_access_enabled               = true
  name                                          = "PE-AKV"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = azurerm_resource_group.res-0.name
  service_endpoint_policy_ids                   = []
  service_endpoints                             = []
  virtual_network_name                          = "VLK-VNet"
  depends_on = [
    azurerm_virtual_network.res-36,
  ]
}
resource "azurerm_subnet" "res-41" {
  address_prefixes                              = ["10.0.1.96/29"]
  default_outbound_access_enabled               = true
  name                                          = "PE-ASA-DL"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = azurerm_resource_group.res-0.name
  service_endpoint_policy_ids                   = []
  service_endpoints                             = []
  virtual_network_name                          = "VLK-VNet"
  depends_on = [
    azurerm_virtual_network.res-36,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-42" {
  network_security_group_id = azurerm_network_security_group.res-12.id
  subnet_id                 = azurerm_subnet.res-41.id
}
resource "azurerm_subnet" "res-43" {
  address_prefixes                              = ["10.0.1.64/28"]
  default_outbound_access_enabled               = true
  name                                          = "Private-ADB"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = azurerm_resource_group.res-0.name
  service_endpoint_policy_ids                   = []
  service_endpoints                             = []
  virtual_network_name                          = "VLK-VNet"
  delegation {
    name = "databricks-del-wkehkby3rdx3g"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      name    = "Microsoft.Databricks/workspaces"
    }
  }
  depends_on = [
    azurerm_virtual_network.res-36,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-44" {
  network_security_group_id = azurerm_network_security_group.res-15.id
  subnet_id                 = azurerm_subnet.res-43.id
}
resource "azurerm_subnet" "res-45" {
  address_prefixes                              = ["10.0.1.80/28"]
  default_outbound_access_enabled               = true
  name                                          = "Public-ADB"
  private_endpoint_network_policies             = "Disabled"
  private_link_service_network_policies_enabled = true
  resource_group_name                           = azurerm_resource_group.res-0.name
  service_endpoint_policy_ids                   = []
  service_endpoints                             = []
  virtual_network_name                          = "VLK-VNet"
  delegation {
    name = "databricks-del-wkehkby3rdx3g"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action", "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action", "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"]
      name    = "Microsoft.Databricks/workspaces"
    }
  }
  depends_on = [
    azurerm_virtual_network.res-36,
  ]
}
resource "azurerm_subnet_network_security_group_association" "res-46" {
  network_security_group_id = azurerm_network_security_group.res-15.id
  subnet_id                 = azurerm_subnet.res-45.id
}
resource "azurerm_storage_account" "res-47" {
  access_tier                       = "Hot"
  account_kind                      = "StorageV2"
  account_replication_type          = "LRS"
  account_tier                      = "Standard"
  allow_nested_items_to_be_public   = false
  allowed_copy_scope                = ""
  cross_tenant_replication_enabled  = false
  default_to_oauth_authentication   = false
  dns_endpoint_type                 = "Standard"
  edge_zone                         = ""
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = false
  is_hns_enabled                    = true
  large_file_share_enabled          = true
  local_user_enabled                = true
  location                          = "westeurope"
  min_tls_version                   = "TLS1_2"
  name                              = "vlkasa"
  nfsv3_enabled                     = false
  primary_access_key                = "" # Masked sensitive attribute
  primary_blob_connection_string    = "" # Masked sensitive attribute
  primary_connection_string         = "" # Masked sensitive attribute
  public_network_access_enabled     = false
  queue_encryption_key_type         = "Service"
  resource_group_name               = azurerm_resource_group.res-0.name
  secondary_access_key              = "" # Masked sensitive attribute
  secondary_blob_connection_string  = "" # Masked sensitive attribute
  secondary_connection_string       = "" # Masked sensitive attribute
  sftp_enabled                      = false
  shared_access_key_enabled         = true
  table_encryption_key_type         = "Service"
  tags = {
    "Support Contact" = "Vijay Ganji"
  }
  blob_properties {
    change_feed_enabled           = false
    change_feed_retention_in_days = 0
    default_service_version       = ""
    last_access_time_enabled      = false
    versioning_enabled            = false
    container_delete_retention_policy {
      days = 7
    }
    delete_retention_policy {
      days                     = 7
      permanent_delete_enabled = false
    }
  }
  network_rules {
    bypass                     = ["AzureServices"]
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
  share_properties {
    retention_policy {
      days = 7
    }
  }
}
resource "azurerm_private_dns_a_record" "res-53" {
  name                = "adb-1993096997059620.0"
  records             = ["10.0.1.52"]
  resource_group_name = "rg-vlk"
  tags = {
    creator = "created by private endpoint PE-ADB with resource guid c309d14f-e0e5-49fa-a1c2-01226a9d7296"
  }
  ttl       = 10
  zone_name = "privatelink.azuredatabricks.net"
  depends_on = [
    azurerm_private_dns_zone.res-22,
  ]
}
resource "azurerm_private_dns_a_record" "res-55" {
  name                = "vlkasa"
  records             = ["10.0.1.100"]
  resource_group_name = "rg-vlk"
  tags                = {}
  ttl                 = 3600
  zone_name           = "privatelink.blob.core.windows.net"
  depends_on = [
    azurerm_private_dns_zone.res-24,
  ]
}
resource "azurerm_private_dns_a_record" "res-57" {
  name                = "vlk-adf.westeurope"
  records             = ["10.0.1.108"]
  resource_group_name = "rg-vlk"
  tags = {
    creator = "created by private endpoint PE-VLK-ADF with resource guid 8e88d668-470a-4727-bd07-eeb5559ec761"
  }
  ttl       = 10
  zone_name = "privatelink.datafactory.azure.net"
  depends_on = [
    azurerm_private_dns_zone.res-26,
  ]
}
resource "azurerm_private_dns_a_record" "res-59" {
  name                = "vlk-akv"
  records             = ["10.0.1.36"]
  resource_group_name = "rg-vlk"
  tags                = {}
  ttl                 = 3600
  zone_name           = "privatelink.vaultcore.azure.net"
  depends_on = [
    azurerm_private_dns_zone.res-28,
  ]
}


