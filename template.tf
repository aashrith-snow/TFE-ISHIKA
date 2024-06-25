data "azurerm_virtual_network" "tfresource" {
  name                = "${var.network}"
  resource_group_name = "${var.networkResourceGroup}"
}

data "azurerm_subnet" "tfresource" {
  name                 = "${var.subnet}"
  resource_group_name  = "${var.networkResourceGroup}"
  virtual_network_name = data.azurerm_virtual_network.tfresource.name
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
  name                = "${var.vmName}-nic"
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
    admin_username = "azureuser"
    admin_password = "Password!123"
  }
  os_profile_linux_config {
    disable_password_authentication = "false"
  }

  storage_os_disk {
    name		= "${var.vmName}-os-disk"
    caching              = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  delete_os_disk_on_termination = "true"
  delete_data_disks_on_termination = true

}

resource "azurerm_managed_disk" "storage_disks" {
  name                 = "${var.vmName}-disk-0"
  location             = "${var.region}"
  resource_group_name  = "${var.isNewResourceGroup ? azurerm_resource_group.tfresource[0].name : var.existingResourceGroup}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "20"
  max_shares           = "0"
  tags = {
    environment = "staging"
    tag1 = "value1"
    tag2 = "value2"
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachments" {
  for_each           = azurerm_managed_disk.storage_disks
  managed_disk_id    = each.value.id
  virtual_machine_id = azurerm_virtual_machine.tfresource.id
  lun                = each.key
  caching            = "None"
}
