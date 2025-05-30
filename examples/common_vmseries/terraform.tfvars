# GENERAL

region              = "East US"
resource_group_name = "transit-vnet"
name_prefix         = "gstan-"
tags = {
  "CreatedBy"     = "Palo Alto Networks"
  "CreatedWith"   = "Terraform"
  "xdr-exclusion" = "yes"
}

# NETWORK

vnets = {
  "transit" = {
    name          = "transit"
    address_space = ["10.0.0.0/16"]
    network_security_groups = {
      "management" = {
        name = "mgmt-nsg"
        rules = {
          mgmt_inbound = {
            name                       = "vmseries-management-allow-inbound"
            priority                   = 100
            direction                  = "Inbound"
            access                     = "Allow"
            protocol                   = "Tcp"
            source_address_prefixes    = ["0.0.0.0/0"] # TODO: Whitelist public IP addresses that will be used to manage the appliances
            source_port_range          = "*"
            destination_address_prefix = "10.0.0.0/28"
            destination_port_ranges    = ["22", "443"]
          }
        }
      }
      "public" = {
        name = "public-nsg"
      }
      "ngfw" = {
        name = "ngfw-nsg"
        rules = {
              ngfw-vnet-inbound = {
                name                       = "ngfw-allow-all"
                priority                   = 100
                direction                  = "Inbound"
                access                     = "Allow"
                protocol                   = "*"
                source_address_prefixes    = ["0.0.0.0/0"]
                source_port_range          = "*"
                destination_address_prefix = "*"
                destination_port_range     = "*"
          }
        }
      }
     }
    route_tables = {
      "management" = {
        name = "mgmt-rt"
        routes = {
          "private_blackhole" = {
            name           = "private-blackhole-udr"
            address_prefix = "10.0.0.16/28"
            next_hop_type  = "None"
          }
          "public_blackhole" = {
            name           = "public-blackhole-udr"
            address_prefix = "10.0.0.32/28"
            next_hop_type  = "None"
          }
          "appgw_blackhole" = {
            name           = "appgw-blackhole-udr"
            address_prefix = "10.0.0.48/28"
            next_hop_type  = "None"
          }
        }
      }
      "private" = {
        name = "private-rt"
        routes = {
          "default" = {
            name                = "default-udr"
            address_prefix      = "0.0.0.0/0"
            next_hop_type       = "VirtualAppliance"
            next_hop_ip_address = "10.0.0.30"
          }
          "mgmt_blackhole" = {
            name           = "mgmt-blackhole-udr"
            address_prefix = "10.0.0.0/28"
            next_hop_type  = "None"
          }
          "public_blackhole" = {
            name           = "public-blackhole-udr"
            address_prefix = "10.0.0.32/28"
            next_hop_type  = "None"
          }
          "appgw_blackhole" = {
            name           = "appgw-blackhole-udr"
            address_prefix = "10.0.0.48/28"
            next_hop_type  = "None"
          }
        }
      }
      "public" = {
        name = "public-rt"
        routes = {
          "mgmt_blackhole" = {
            name           = "mgmt-blackhole-udr"
            address_prefix = "10.0.0.0/28"
            next_hop_type  = "None"
          }
          "private_blackhole" = {
            name           = "private-blackhole-udr"
            address_prefix = "10.0.0.16/28"
            next_hop_type  = "None"
          }
        }
      }
      "ngfw-app-gw" = {
        name = "ngfw-app-gw-rt"
        routes = {
          "spoke1" = {
            name           = "spoke1-udr"
            address_prefix = "10.100.0.0/25"
            next_hop_type       = "VirtualAppliance"
            next_hop_ip_address = "10.0.2.4"
          }
          "spoke2" = {
            name           = "spoke2-udr"
            address_prefix      = "10.100.1.0/25"
            next_hop_type       = "VirtualAppliance"
            next_hop_ip_address = "10.0.2.4"
          }
        }
      }
    }
    subnets = {
      "management" = {
        name                            = "mgmt-snet"
        address_prefixes                = ["10.0.0.0/28"]
        network_security_group_key      = "management"
        route_table_key                 = "management"
        enable_storage_service_endpoint = true
      }
      "private" = {
        name             = "private-snet"
        address_prefixes = ["10.0.0.16/28"]
        route_table_key  = "private"
      }
      "public" = {
        name                       = "public-snet"
        address_prefixes           = ["10.0.0.32/28"]
        network_security_group_key = "public"
        route_table_key            = "public"
      }
      "appgw" = {
        name             = "appgw-snet"
        address_prefixes = ["10.0.0.48/28"]
        route_table_key  = "cngfw-app-gw"
      }
      "cngfw-public" = {
        name             = "ngfw-public-snet"
        network_security_group_key = "ngfw"
        address_prefixes = ["10.0.1.0/24"]
      }
      "cngfw-private" = {
        name             = "ngfw-private-snet"
        network_security_group_key = "ngfw"
        address_prefixes = ["10.0.2.0/24"]
      }
    }
  }
}

vnet_peerings = {
  # "vmseries-to-panorama" = {
  #   local_vnet_name            = "example-transit"
  #   remote_vnet_name           = "example-panorama-vnet"
  #   remote_resource_group_name = "example-panorama"
  # }
}

#natgws = {
#  "natgw" = {
#    name        = "public-natgw"
#   vnet_key    = "transit"
#    subnet_keys = ["public", "management"]
#    public_ip_prefix = {
#      create = true
#      name   = "public-natgw-ippre"
#      length = 29
#    }
#  }
#}

# LOAD BALANCING

load_balancers = {
  "public" = {
    name = "public-lb"
    nsg_auto_rules_settings = {
      nsg_vnet_key = "transit"
      nsg_key      = "public"
      source_ips   = ["0.0.0.0/0"] # TODO: Whitelist public IP addresses that will be used to access LB
    }
    frontend_ips = {
      "app1" = {
        name             = "app1"
        public_ip_name   = "public-lb-app1-pip"
        create_public_ip = true
        in_rules = {
          "balanceHttp" = {
            name     = "HTTP"
            protocol = "Tcp"
            port     = 80
          }
        }
      }
    }
  }
  "private" = {
    name     = "private-lb"
    vnet_key = "transit"
    frontend_ips = {
      "ha-ports" = {
        name               = "private-vmseries"
        subnet_key         = "private"
        private_ip_address = "10.0.0.30"
        in_rules = {
          HA_PORTS = {
            name     = "HA-ports"
            port     = 0
            protocol = "All"
          }
        }
      }
    }
  }
}

appgws = {
  public = {
    name       = "appgw"
    vnet_key   = "transit"
    subnet_key = "appgw"
    public_ip = {
      name = "appgw-pip"
    }
    listeners = {
      "http" = {
        name = "http"
        port = 80
      }
    }
    backend_settings = {
      http = {
        name     = "http"
        port     = 80
        protocol = "Http"
      }
    }
    rewrites = {
      xff = {
        name = "XFF-set"
        rules = {
          "xff-strip-port" = {
            name     = "xff-strip-port"
            sequence = 100
            request_headers = {
              "X-Forwarded-For" = "{var_add_x_forwarded_for_proxy}"
            }
          }
        }
      }
    }
    rules = {
      "http" = {
        name         = "http"
        listener_key = "http"
        backend_key  = "http"
        rewrite_key  = "xff"
        priority     = 1
      }
    }
  }
}

# VM-SERIES
vmseries_universal = {
  version           = "11.2.302"
  size              = "Standard_D3_v2"
  bootstrap_options = <<-EOT
    panorama-server=172.210.8.228
    authcodes=D9273329
    vm-auth-key=388104403362258
    type=dhcp-client
    dhcp-accept-server-hostname=yes
    dns-primary=8.8.8.8
    dns-secondary=4.2.2.2
    tplname=gstan-pavm
    dgname=dgname=AZR
    vm-series-auto-registration-pin-id=576208cb-0921-4cad-a00c-f8e15f0d8026
    vm-series-auto-registration-pin-value=fd593deae81d467591e182ada0d2f33e
    EOT
}

vmseries = {
  "ngfw01" = {
    name     = "ngfw01"
    vnet_key = "transit"
    virtual_machine = {
      zone = 1
    }
    interfaces = [
      {
        name             = "ngfw01-mgmt"
        subnet_key       = "management"
        create_public_ip = true
      },
      {
        name              = "ngfw01-private"
        subnet_key        = "private"
        load_balancer_key = "private"
      },
      {
        name                    = "ngfw01-public"
        subnet_key              = "public"
        create_public_ip        = true
        load_balancer_key       = "public"
        application_gateway_key = "public"
      }
    ]
  }
  "ngfw02" = {
    name     = "ngfw02"
    vnet_key = "transit"
    virtual_machine = {
      zone = 1
    }
    interfaces = [
      {
        name             = "ngfw02-mgmt"
        subnet_key       = "management"
        create_public_ip = true
      },
      {
        name              = "ngfw02-private"
        subnet_key        = "private"
        load_balancer_key = "private"
      },
      {
        name                    = "ngfw02-public"
        subnet_key              = "public"
        create_public_ip        = true
        load_balancer_key       = "public"
        application_gateway_key = "public"
      }
    ]
  }
}

# TEST INFRASTRUCTURE

test_infrastructure = {
  "app1_testenv" = {
    vnets = {
      "app1" = {
        name          = "app1-vnet"
        address_space = ["10.100.0.0/25"]
        hub_vnet_name = "transit" # Name prefix is added to the beginning of this string
        network_security_groups = {
          "app1" = {
            name = "app1-nsg"
            rules = {
              from_bastion = {
                name                       = "app1-mgmt-allow-bastion"
                priority                   = 100
                direction                  = "Inbound"
                access                     = "Allow"
                protocol                   = "Tcp"
                source_address_prefix      = "10.100.0.64/26"
                source_port_range          = "*"
                destination_address_prefix = "*"
                destination_port_range     = "*"
              }
              web_inbound = {
                name                       = "app1-web-allow-inbound"
                priority                   = 110
                direction                  = "Inbound"
                access                     = "Allow"
                protocol                   = "Tcp"
                source_address_prefixes    = ["0.0.0.0/0"] # TODO: Whitelist public IP addresses that will be used to access test infrastructure
                source_port_range          = "*"
                destination_address_prefix = "10.100.0.0/25"
                destination_port_ranges    = ["80", "443"]
              }
            }
          }
        }
        route_tables = {
          nva = {
            name = "app1-rt"
            routes = {
              "toNVA" = {
                name                = "toNVA-udr"
                address_prefix      = "0.0.0.0/0"
                next_hop_type       = "VirtualAppliance"
                next_hop_ip_address = "10.0.0.30"
              }
              "toAppGW" = {
                name                = "toAppGW-udr"
                address_prefix      = "10.0.0.48/28"
                next_hop_type       = "VirtualAppliance"
                next_hop_ip_address = "10.0.2.4"
              }
            }
          }
        }
        subnets = {
          "vms" = {
            name                       = "vms-snet"
            address_prefixes           = ["10.100.0.0/26"]
            network_security_group_key = "app1"
            route_table_key            = "nva"
          }
          "bastion" = {
            name             = "AzureBastionSubnet"
            address_prefixes = ["10.100.0.64/26"]
          }
        }
      }
    }
    spoke_vms = {
      "app1_vm" = {
        name       = "app1-vm"
        vnet_key   = "app1"
        subnet_key = "vms"
      }
    }
    bastions = {
      "app1_bastion" = {
        name       = "app1-bastion"
        vnet_key   = "app1"
        subnet_key = "bastion"
      }
    }
  }
  "app2_testenv" = {
    vnets = {
      "app2" = {
        name          = "app2-vnet"
        address_space = ["10.100.1.0/25"]
        hub_vnet_name = "transit" # Name prefix is added to the beginning of this string
        network_security_groups = {
          "app2" = {
            name = "app2-nsg"
            rules = {
              from_bastion = {
                name                       = "app2-mgmt-allow-bastion"
                priority                   = 100
                direction                  = "Inbound"
                access                     = "Allow"
                protocol                   = "Tcp"
                source_address_prefix      = "10.100.1.64/26"
                source_port_range          = "*"
                destination_address_prefix = "*"
                destination_port_range     = "*"
              }
              web_inbound = {
                name                       = "app2-web-allow-inbound"
                priority                   = 110
                direction                  = "Inbound"
                access                     = "Allow"
                protocol                   = "Tcp"
                source_address_prefixes    = ["0.0.0.0/0"] # TODO: Whitelist public IP addresses that will be used to access test infrastructure
                source_port_range          = "*"
                destination_address_prefix = "10.100.1.0/25"
                destination_port_ranges    = ["80", "443"]
              }
            }
          }
        }
        route_tables = {
          nva = {
            name = "app2-rt"
            routes = {
              "toNVA" = {
                name                = "toNVA-udr"
                address_prefix      = "0.0.0.0/0"
                next_hop_type       = "VirtualAppliance"
                next_hop_ip_address = "10.0.0.30"
              }
              "toAppGW" = {
                name                = "toAppGW-udr"
                address_prefix      = "10.0.0.48/28"
                next_hop_type       = "VirtualAppliance"
                next_hop_ip_address = "10.0.2.4"
              }
            }
          }
        }
        subnets = {
          "vms" = {
            name                       = "vms-snet"
            address_prefixes           = ["10.100.1.0/26"]
            network_security_group_key = "app2"
            route_table_key            = "nva"
          }
          "bastion" = {
            name             = "AzureBastionSubnet"
            address_prefixes = ["10.100.1.64/26"]
          }
        }
      }
    }
    spoke_vms = {
      "app2_vm" = {
        name       = "app2-vm"
        vnet_key   = "app2"
        subnet_key = "vms"
      }
    }
    bastions = {
      "app2_bastion" = {
        name       = "app2-bastion"
        vnet_key   = "app2"
        subnet_key = "bastion"
      }
    }
  }
}
