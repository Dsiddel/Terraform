# Very basic, was my learning experience to create multiple vm's on the same template, a bit dissapointed you can't use count with modules

provider "azurerm" {
  version = ">=1.20.0"

  subscription_id = "d470d623-39f9-4dc6-865e-27fb601f140f"
  client_id       = "c443f0f7-527c-4e4f-8504-1066cadaf9ce"
  client_secret   = "${var.client_secret}"
  tenant_id       = "80708e2a-846b-4b81-9868-f79892e7265d"
}


resource "azurerm_resource_group" "main" {
  name     = "TerraformRG1"
  location = "Australia East"

  tags {
    environment = "Production"
  }
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "main" {
  count               = "${var.count}"
  name                = "${var.prefix}-nic-${count.index}"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_virtual_machine" "Set" {
  count                          = "${var.count}"
  name                           = "${var.prefix}-${count.index}"
  location                       = "${azurerm_resource_group.main.location}"
  resource_group_name            = "${azurerm_resource_group.main.name}"
  vm_size                        = "Standard_DS1_v2"
  network_interface_ids          = ["${element(azurerm_network_interface.main.*.id, count.index)}"]
  delete_os_disk_on_termination  = true
  delete_data_disks_on_termination = true
    storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags {
    environment = "staging"
  }
}




/*


module "network" {
    source              = "Azure/network/azurerm"
    vnet_name           = "Terraform_Vnet"
    resource_group_name = "${azurerm_resource_group.TerraformRG1.name}"
    location            = "Australia East"
    address_space       = "10.0.0.0/16"
    subnet_prefixes     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
    subnet_names        = ["subnet1", "subnet2", "subnet3", "subnet4"]

    tags                = {
                            environment = "dev"
                            costcenter  = "it"
                          }
}


module "compute" {
  source  = "Azure/compute/azurerm"
  version = "1.2.0"
  count = "${var.count}"
  location = "Australia East"
  resource_group_name = "TerraformRG1"
  vnet_subnet_id = "${module.network.vnet_subnets[0]}"
  is_windows_image = "true"
  nb_public_ip = "0"
  vm_os_simple = "WindowsServer-${count.index}-os"
  admin_password = "Password1234!"
  admin_username = "Codify"
}
*/