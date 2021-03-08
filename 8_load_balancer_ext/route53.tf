data "aws_route53_zone" "ocp_public" {
  name = var.domain
  private_zone = false
}

resource "aws_route53_record" "master_api" {
  count     = var.create_external_loadbalancer ? 1 : 0
  name      = "api.${var.clustername}.${var.domain}"
  type      = "A"
  zone_id   =  data.aws_route53_zone.ocp_public.zone_id

  alias {
    name =  aws_lb.ocp_control_plane_ext[count.index].dns_name
    zone_id =  aws_lb.ocp_control_plane_ext[count.index].zone_id
    evaluate_target_health  = true
  }
}
