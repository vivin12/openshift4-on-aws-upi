data "aws_vpc" "ocp_vpc" {
  id =  var.private_vpc_id
}

# Create private subnet in each AZ for the worker nodes to reside in
data "aws_subnet" "ocp_pub_subnet" {
  count       =  length(var.private_vpc_public_subnet_ids)
  id          = "${element(var.private_vpc_public_subnet_ids, count.index)}"
}
