provider "aws" {
  region =  var.aws_region
}

data "aws_caller_identity" "current" {
}

resource "random_string" "clusterid" {
  length = 5
  upper = false
  special = false
}

locals {
  infrastructure_id = "${var.infrastructure_id != "" ? "${var.infrastructure_id}" : "${var.clustername}-${random_string.clusterid.result}"}"
}
