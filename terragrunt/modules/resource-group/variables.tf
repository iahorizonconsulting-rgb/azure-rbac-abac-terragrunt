# ============================================================================
# VARIABLES: RESOURCE GROUP MODULE
# ============================================================================

variable "app_name" {
  description = "Nom de l'application"
  type        = string
  
  validation {
    condition     = length(var.app_name) >= 3 && length(var.app_name) <= 24
    error_message = "Le nom de l'application doit contenir entre 3 et 24 caractères."
  }
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "L'environnement doit être dev, staging ou prod."
  }
}

variable "location" {
  description = "Région Azure pour le déploiement"
  type        = string
  
  validation {
    condition     = contains(["westeurope", "northeurope", "francecentral", "eastus", "westus2"], var.location)
    error_message = "La région doit être une région Azure valide."
  }
}

variable "tags" {
  description = "Tags à appliquer au resource group"
  type        = map(string)
  default     = {}
}