# The cl
variable "envid" {
  type     = string
  nullable = false
}

# Grab H2 Zone id
data "aws_route53_zone" "h2" {
  name = "h2.hmdc.harvard.edu."
}

# Grab environment id from table. This should be initiated from CI somewhere.
data "aws_dynamodb_table_item" "env" {
  table_name = "h2env"
  key        = <<KEY
  {
    "PK": {"S": "${var.envid}"},
    "SK": {"S": "env#"}
  }
  KEY
}

provider "aws" {
  region = "us-east-1"
}

provider "openstack" {
  cloud = "nerc"
}
