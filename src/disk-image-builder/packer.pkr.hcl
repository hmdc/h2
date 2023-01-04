# Get the cloud yaml and install it in the right place
# Example:
# ➜  mkdir ~/.config/openstack
# ➜  cp ~/Downloads/clouds.yaml ~/.config/openstack/
packer {
  required_plugins {
    openstack = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/openstack"
    }
  }
}

# This is here if we need to manually set credentials but I think we should always use cloud-yaml? 
# Cloud-yaml doesn't include the password field so will need to be documented.
variable "os_username" {
  type    = string
  default = null
}

variable os_identity_endpoint {
  type    = string
  default = null

}

variable os_tenant_id {
  type    = string
  default = null

}

variable os_password {
  type    = string
  default = null

}

variable os_region {
  type    = string
  default = null

}

variable os_source_image {
  type    = string
  default = null
}

variable os_flavor {
  type    = string
  default = null
}

variable os_cloud {
  type    = string
  default = null
}

variable os_floating_ip {
  type    = string
  default = null
}

variable os_floating_ip_network {
  type    = string
  default = null
}

locals {
  build_start_time = formatdate("YYYYMMDDhhmmss", timestamp())
  # H2.{parent image id}.{timestamp}
  encoded_os_image_name = "h2.${var.os_source_image}.${local.build_start_time}"
}

source "openstack" "h2-node" {
  username            = var.os_username
  password            = var.os_password
  flavor              = var.os_flavor
  identity_endpoint   = var.os_identity_endpoint
  tenant_id           = var.os_tenant_id
  region              = var.os_region
  source_image        = var.os_source_image
  cloud               = var.os_cloud
  floating_ip         = var.os_floating_ip
  floating_ip_network = var.os_floating_ip_network
  image_name          = local.encoded_os_image_name
  security_groups     = ["build"]
  domain_name         = "Default"
  ssh_username        = "ubuntu"
}

build {
  sources = ["source.openstack.h2-node"]
  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "TZ=America/New_York"
    ]
    script = "provision.sh"
  }
}