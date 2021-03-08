output "int_lb_url" {
    value =  data.aws_lb.ocp_control_plane_int.dns_name
}

output "clustername" {
    value =  var.clustername
}

output "master_nodes" {
    value = aws_instance.master.*.id
}
