variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "brit-infra-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "UK South"
}

variable "prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "brit"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "Production"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureadmin"
}

variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}

variable "allowed_ip" {
  description = "IP address allowed for RDP"
  type        = string
}

variable "admin_principal_id" {
  description = "Principal ID for RBAC assignment"
  type        = string
}
