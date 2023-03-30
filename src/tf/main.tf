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

  # Partition Key.
  attribute {
    name = "PK"
    type = "S"
  }

  # Sort Key (datetime in UTC).
  attribute {
    name = "SK"
    type = "S"
  }
}


provider "aws" {
  region = "us-east-1"
}
