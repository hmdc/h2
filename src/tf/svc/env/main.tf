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
  name = "h2.hmdc.harvard.edu"
}

data "openstack_networking_router_v2" "primary_router" {
  name = "default_router"
}

data "openstack_networking_network_v2" "primary_network" {
  name = "default_network"
}

data "openstack_networking_secgroup_v2" "ssh" {
  secgroup_id = "1390789d-030b-414e-bf7a-2513dca420a8"
}

data "openstack_networking_secgroup_v2" "caprover" {
  secgroup_id = "fa0acc10-4fec-47c9-b892-c0c8dfd090c5"
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

resource "openstack_networking_port_v2" "subnet_1" {
  name           = local.__envid
  network_id     = data.openstack_networking_network_v2.primary_network.id
  admin_state_up = true
  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet_1.id
  }
}

resource "openstack_networking_port_secgroup_associate_v2" "subnet_1" {
  port_id = openstack_networking_port_v2.subnet_1.id
  security_group_ids = [
    data.openstack_networking_secgroup_v2.caprover.id,
    data.openstack_networking_secgroup_v2.ssh.id
  ]
}

resource "openstack_networking_floatingip_v2" "floatip_1" {
  pool = "provider"
}

resource "openstack_networking_floatingip_associate_v2" "floatip_1" {
  floating_ip = openstack_networking_floatingip_v2.floatip_1.fixed_ip
  port_id     = openstack_networking_port_v2.subnet_1.id
}

// MAIN_NODE_IP_ADDRESS
resource "aws_route53_record" "env" {
  zone_id = data.aws_route53_zone.h2.zone_id
  name    = "*.${var.envid}"
  type    = "A"
  ttl     = 5

  records = [openstack_networking_floatingip_v2.floatip_1.address]
}

resource "openstack_compute_instance_v2" "srv" {
  name        = local.__envid
  image_id    = "48d5beed-77ee-4a84-8686-1981e61c9d2f"
  flavor_name = "cpu-a.2"
  key_pair    = "test1"
  user_data   = <<-EOT
#!/usr/bin/bash
echo "MAIN_NODE_IP_ADDRESS=${openstack_networking_floatingip_v2.floatip_1.address}" > /etc/h2.env
EOT
  network {
    port = openstack_networking_port_v2.subnet_1.id
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "openstack" {
  cloud = "nerc"
}
