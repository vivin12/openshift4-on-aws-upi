output "private_vpc_id" {
    value =  data.aws_vpc.ocp_vpc.id
}

output "clustername" {
    value =  var.clustername
}

output "domain" {
  value = var.domain
}

output "ocp_control_plane_lb_ext_arn" {
    value =  aws_lb.ocp_control_plane_ext.*.arn
}

output "ocp_control_plane_lb_ext_6443_tg_arn" {
    value =  aws_lb_target_group.ocp_control_plane_ext_6443.*.arn
}
