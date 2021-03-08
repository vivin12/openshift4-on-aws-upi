resource "aws_lb" "ocp_control_plane_ext" {
  count = var.create_external_loadbalancer ? 1 : 0
  name =  "${var.infrastructure_id}-ext"

  load_balancer_type = "network"
  internal = "false"
  subnets =  data.aws_subnet.ocp_pub_subnet.*.id

  tags =  var.default_tags
}

resource "aws_lb_listener" "ocp_control_plane_ext_6443" {
  count = var.create_external_loadbalancer ? 1 : 0
  load_balancer_arn = aws_lb.ocp_control_plane_ext[count.index].arn

  port = "6443"
  protocol = "TCP"

  default_action {
    target_group_arn =  aws_lb_target_group.ocp_control_plane_ext_6443[count.index].arn
    type = "forward"
  }
}

resource "aws_lb_target_group" "ocp_control_plane_ext_6443" {
  count = var.create_external_loadbalancer ? 1 : 0
  name =  "${var.infrastructure_id}-6443-ext-tg"
  port = 6443
  protocol = "TCP"
  tags =  var.default_tags
  target_type = "ip"
  vpc_id =  data.aws_vpc.ocp_vpc.id
  deregistration_delay = 60
}

resource "aws_vpc_endpoint_service" "ocp_control_plane_ep_ext" {
  count = var.create_external_loadbalancer ? 1 : 0
  acceptance_required = false
  network_load_balancer_arns = [aws_lb.ocp_control_plane_ext[count.index].arn]

  tags =  merge(
    var.default_tags,
    map(
      "Name",  "${var.infrastructure_id}-control-plane-vpce"
    )
  )

}

data "aws_instance" "master" {
  //count = lookup(var.master_nodes, "count", 3)
  count = length(var.master_nodes)

  instance_id = var.master_nodes[count.index]

}

resource "aws_lb_target_group_attachment" "ocp_master_control_plane_ext_6443" {
    count = var.create_external_loadbalancer ? length(var.master_nodes) :0
    target_group_arn = aws_lb_target_group.ocp_control_plane_ext_6443[0].arn
    target_id = element(data.aws_instance.master.*.private_ip, count.index)
}
