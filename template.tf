data "azurerm_virtual_network" "tfresource" {
  name                = "${var.network}"
  resource_group_name = "${var.networkResourceGroup}"
}

data "azurerm_subnet" "tfresource" {
  name                 = "${var.subnet}"
  resource_group_name  = "${var.networkResourceGroup}"
  virtual_network_name = data.azurerm_virtual_network.tfresource.name
}

locals {
  _isSSHKey = "${var.isPassword ? {} : { empty = true }}"
}

resource "azurerm_resource_group" "tfresource" {
  count = "${var.isNewResourceGroup ? 1 : 0}"
  name = "${var.newResourceGroup}"
  location = "${var.region}"
}

resource "azurerm_public_ip" "tfresource" {
  name                = "${var.vmName}-public-ip"
  resource_group_name = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  location            = "${var.region}"
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "tfresource" {
  name                = "${var.nic}"
  location            = "${var.region}"
  resource_group_name = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.tfresource.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.tfresource.id
  }
}

resource "azurerm_virtual_machine" "tfresource" {
  name                = "${var.vmName}"
  resource_group_name = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  location            = "${var.region}"
  vm_size                = "${var.size}"
  network_interface_ids = [
    azurerm_network_interface.tfresource.id,
  ]

  os_profile {
    computer_name  = "${var.vmName}"
    admin_username = "${var.adminUserName}"
    admin_password = "${var.isPassword ? var.password : null}"
  }
  os_profile_linux_config {
    disable_password_authentication = "${var.isPassword ? false : true}"
    dynamic "ssh_keys" {
      for_each = local._isSSHKey
      content {
        key_data = "${var.publicKey}"
        path = "/home/${var.adminUserName}/.ssh/authorized_keys"
      }
    }
  }

  storage_os_disk {
    name		= "${var.vmName}-os-disk"
    caching              = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  delete_os_disk_on_termination = "${var.deleteOSDiskOnTerm}"
  delete_data_disks_on_termination = true

}

resource "azurerm_managed_disk" "storage_disks" {
  for_each             = { for idx, disk in var.disks : idx => disk }
  name                 = "${var.vmName}-disk-${each.key}"
  location             = "${var.region}"
  resource_group_name  = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  storage_account_type = "${each.value.volume_type}"
  create_option        = "Empty"
  disk_size_gb         = "${each.value.volume_size}"
  max_shares           = "${each.value.max_shares != null && each.value.max_shares > 1 ? each.value.max_shares : null}"
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachments" {
  for_each           = azurerm_managed_disk.storage_disks
  managed_disk_id    = each.value.id
  virtual_machine_id = azurerm_virtual_machine.tfresource.id
  lun                = each.key
  caching            = "None"
}