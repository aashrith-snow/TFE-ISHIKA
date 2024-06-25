variable clientId {}
variable clientSecret {}
variable region {}
variable subscriptionId {}
variable tenantId {}

variable isNewResourceGroup {
  type = bool
}
variable newResourceGroup {}
variable existingResourceGroup {}
variable vmName {}

variable network {}
variable subnet {}
variable networkResourceGroup {}
variable nic {}
variable size {}
variable adminUserName {}
variable publicKey {}
variable isPassword {
  type = bool
}
variable password {}

variable image_publisher {}
variable image_offer {}
variable image_sku {}
variable image_version {}

variable deleteOSDiskOnTerm {
  type = bool
}

variable "disks" {
  type = list(object({
    volume_size  = number
    volume_type  = string
    max_shares = number
  }))
}