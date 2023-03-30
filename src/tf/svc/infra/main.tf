terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# A table of all H2 environments,users+

resource "aws_dynamodb_table" "h2env" {
  name         = "h2env"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "PK" # partition key
  range_key    = "SK" # sort key

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "gs1pk"
    type = "S"
  }

  attribute {
    name = "gs1sk"
    type = "S"
  }

  global_secondary_index {
    name            = "gs1"
    hash_key        = "gs1pk"
    range_key       = "gs1sk"
    projection_type = "ALL"
  }

}


provider "aws" {
  region = "us-east-1"
}
