variable "RG_NAME" {
  description = "Resource group name"
}

variable "LOCATION" {
  description = "location of resource deployment"
}

variable "ENVIRONMENT" {
    description = "Environment of the deployment"
  
}

variable "ADB_NAME" {
  description = "Azure Data Bricks Name"
}

variable "ASA_DL_NAME" {
  description = "Azure Storage Account Data Lake Name"
}

variable "ADF_NAME" {
  description = "Azure Data Factory Name"
}

variable "AKV_NAME" {
  description = "Azure Key Vault Name"  
}

variable "CONTACT" {
  description = "Whom to contact for any details for the support needed about this resource"  
}
