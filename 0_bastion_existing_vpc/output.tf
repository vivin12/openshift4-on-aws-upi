output "infrastructure_id" {
    value =  local.infrastructure_id
}

output "clustername" {
    value =  var.clustername
}

output "private_vpc_id" {
    value =  data.aws_vpc.ocp_vpc.id
}

# output "private_vpc_private_subnet_ids" {
#     value =  aws_subnet.ocp_pri_subnet.*.id
# }
#
# output "private_vpc_public_subnet_ids" {
#     value =  aws_subnet.ocp_pub_subnet.*.id
# }

output "bastion_elastic_ip" {
    value = aws_eip.bastion_eip.public_ip
}

// write output variables to current directory
resource "local_file" "output_variables" {
    filename = "${path.cwd}/bastion-output.auto.tfvars"

    content = <<EOF
ocp_vpc_id = "${data.aws_vpc.ocp_vpc.id}"
infrastructure_id = "${local.infrastructure_id}"
EOF
}

# ocp_pri_subnet_ids = [
#   %{for id in aws_subnet.ocp_pri_subnet.*.id ~}
#   "${id}",
#   %{endfor ~}
# ]
# ocp_pub_subnet_ids = [
#   %{for id in aws_subnet.ocp_pub_subnet.*.id ~}
#   "${id}",
#   %{endfor ~}
# ]
