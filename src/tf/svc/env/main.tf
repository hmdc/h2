# The cl
variable "envid" {
  type     = string
  nullable = false
}

locals {
  __envid = replace(var.envid, "_", "#")
}

# Grab environment id from table. This should be initiated from CI somewhere.
data "aws_dynamodb_table_item" "env" {
  table_name = "h2env"
  key        = <<KEY
  {
    "PK": {"S": "${local.__envid}"},
    "SK": {"S": "env#"}
  }
  KEY
}

# Grab H2 Zone id
data "aws_route53_zone" "h2" {
  name = "h2.hmdc.harvard.edu."
}

data "openstack_networking_router_v2" "primary_router" {
  name = "default_router"
}

data "openstack_networking_network_v2" "primary_network" {
  name = "default_network"
}

resource "openstack_networking_subnet_v2" "subnet_1" {
  name            = local.__envid
  network_id      = data.openstack_networking_network_v2.primary_network.id
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]
  cidr            = jsondecode(data.aws_dynamodb_table_item.env.item).cidr.S
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = data.openstack_networking_router_v2.primary_router.id
  subnet_id = openstack_networking_subnet_v2.subnet_1.id
}

provider "aws" {
  region = "us-east-1"
}

provider "openstack" {
  cloud = "nerc"
}
