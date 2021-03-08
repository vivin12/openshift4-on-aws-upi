# resource "random_id" "clusterid" {
#   byte_length = "2"
# }
#
# locals {
#   infrastructure_id = var.infrastructure_id != "" ? var.infrastructure_id :  "${var.clustername}-${random_id.clusterid.hex}"
# }

module "private_network" {
  source = "./1_private_network"
  aws_region = var.aws_region
  aws_azs = var.aws_azs
  default_tags = var.default_tags
  infrastructure_id = var.infrastructure_id
  clustername = var.clustername
  vpc_cidr = var.private_vpc_cidr
  vpc_private_subnet_cidrs = var.vpc_private_subnet_cidrs
  vpc_public_subnet_cidrs = var.vpc_public_subnet_cidrs
  ocp_vpc_id = var.ocp_vpc_id
  ocp_pri_subnet_ids = var.ocp_pri_subnet_ids
  ocp_pub_subnet_ids = var.ocp_pub_subnet_ids
}
# ---------------------------
#      module.private_network.infrastructure_id
#      module.private_network.clustername
#      module.private_network.private_vpc_id
#      module.private_network.private_vpc_private_subnet_ids
#      module.private_network.private_vpc_public_subnet_ids
# ---------------------------
module "load_balancer" {
  source = "./2_load_balancer"
  aws_region =  var.aws_region
  default_tags =  var.default_tags
  infrastructure_id =  var.infrastructure_id
  clustername =  var.clustername
  private_vpc_id =  module.private_network.private_vpc_id
  private_vpc_private_subnet_ids =  module.private_network.private_vpc_private_subnet_ids
  private_vpc_public_subnet_ids = module.private_network.private_vpc_public_subnet_ids
  create_external_loadbalancer = var.create_external_loadbalancer
}
# ---------------------------
#      module.load_balancer.private_vpc_id
#      module.load_balancer.infrastructure_id
#      module.load_balancer.clustername
#      module.load_balancer.ocp_control_plane_lb_int_arn
#      module.load_balancer.ocp_control_plane_lb_int_6443_tg_arn
#      module.load_balancer.ocp_control_plane_lb_int_22623_tg_arn
# ---------------------------
module "dns" {
  source = "./3_dns"
  aws_region =  var.aws_region
  default_tags =  var.default_tags
  infrastructure_id =  var.infrastructure_id
  private_vpc_id =  module.private_network.private_vpc_id
  ocp_control_plane_lb_int_arn =  module.load_balancer.ocp_control_plane_lb_int_arn
  clustername =  var.clustername
  domain =  var.domain
}
# ---------------------------
#      module.dns.ocp_route53_private_zone_id
#      module.dns.private_vpc_id
#      module.dns.infrastructure_id
#      module.dns.clustername
#      module.dns.ocp_control_plane_lb_int_arn
# ---------------------------
module "security_group" {
  source = "./4_security_group"
  aws_region =  var.aws_region
  default_tags =  var.default_tags
  clustername =  var.clustername
  infrastructure_id =  var.infrastructure_id
  private_vpc_id =  module.private_network.private_vpc_id
}
# ---------------------------
#      module.security_group.infrastructure_id
#      module.security_group.clustername
#      module.security_group.ocp_control_plane_security_group_id
#      module.security_group.ocp_worker_security_group_id
# ---------------------------
module "iam" {
  source = "./5_iam"
  aws_region =  var.aws_region
  default_tags =  var.default_tags
  infrastructure_id =  var.infrastructure_id
  clustername =  var.clustername
}
# ---------------------------
#      module.iam.infrastructure_id
#      module.iam.clustername
#      module.iam.ocp_master_instance_profile_id
#      module.iam.ocp_worker_instance_profile_id
# ---------------------------
module "bootstrap" {
  source = "./6_bootstrap"
  aws_region =  var.aws_region
  aws_azs =  var.aws_azs
  default_tags =  var.default_tags
  ami =  var.ami
  infrastructure_id =  var.infrastructure_id
  clustername =  var.clustername
  private_vpc_id =  module.private_network.private_vpc_id
  private_vpc_private_subnet_ids =  module.private_network.private_vpc_private_subnet_ids
  domain =  var.domain
  create_ingress_in_public_dns = var.create_ingress_in_public_dns
  cluster_network_cidr =  var.cluster_network_cidr
  cluster_network_host_prefix =  var.cluster_network_host_prefix
  service_network_cidr =  var.service_network_cidr
  bootstrap =  var.bootstrap
  control_plane =  var.control_plane
  worker =  var.worker
  openshift_pull_secret =  var.openshift_pull_secret
  openshift_installer_url =  var.openshift_installer_url
  ocp_control_plane_security_group_id =  module.security_group.ocp_control_plane_security_group_id
  ocp_worker_security_group_id =  module.security_group.ocp_worker_security_group_id
  ocp_master_instance_profile_id =  module.iam.ocp_master_instance_profile_id
  ocp_worker_instance_profile_id =  module.iam.ocp_worker_instance_profile_id
  ocp_control_plane_lb_int_arn =  module.load_balancer.ocp_control_plane_lb_int_arn
  ocp_control_plane_lb_int_22623_tg_arn =  module.load_balancer.ocp_control_plane_lb_int_22623_tg_arn
  ocp_control_plane_lb_int_6443_tg_arn =  module.load_balancer.ocp_control_plane_lb_int_6443_tg_arn
  ocp_route53_private_zone_id =  module.dns.ocp_route53_private_zone_id
}
# ---------------------------
#      module.bootstrap.clustername
#      module.bootstrap.infrastructure_id
#      module.bootstrap.master_ign_64
#      module.bootstrap.worker_ign_64
# ---------------------------
module "control_plane" {
  source = "./7_control_plane"
  aws_region =  var.aws_region
  aws_azs =  var.aws_azs
  default_tags =  var.default_tags
  ami =  var.ami
  infrastructure_id =  var.infrastructure_id
  clustername =  var.clustername
  private_vpc_id =  module.private_network.private_vpc_id
  private_vpc_private_subnet_ids =  module.private_network.private_vpc_private_subnet_ids
  domain =  var.domain
  control_plane =  var.control_plane
  worker =  var.worker
  openshift_pull_secret =  var.openshift_pull_secret
  ocp_control_plane_security_group_id =  module.security_group.ocp_control_plane_security_group_id
  ocp_worker_security_group_id =  module.security_group.ocp_worker_security_group_id
  ocp_master_instance_profile_id =  module.iam.ocp_master_instance_profile_id
  ocp_worker_instance_profile_id =  module.iam.ocp_worker_instance_profile_id
  ocp_control_plane_lb_int_arn =  module.load_balancer.ocp_control_plane_lb_int_arn
  ocp_control_plane_lb_int_22623_tg_arn =  module.load_balancer.ocp_control_plane_lb_int_22623_tg_arn
  ocp_control_plane_lb_int_6443_tg_arn =  module.load_balancer.ocp_control_plane_lb_int_6443_tg_arn
  ocp_route53_private_zone_id =  module.dns.ocp_route53_private_zone_id
  master_ign_64 =  module.bootstrap.master_ign_64
  worker_ign_64 =  module.bootstrap.worker_ign_64
}
module "load_balancer_ext" {
  source = "./8_load_balancer_ext"
  aws_region =  var.aws_region
  default_tags =  var.default_tags
  infrastructure_id =  var.infrastructure_id
  clustername =  var.clustername
  domain = var.domain
  private_vpc_id =  module.private_network.private_vpc_id
  private_vpc_private_subnet_ids =  module.private_network.private_vpc_private_subnet_ids
  private_vpc_public_subnet_ids = module.private_network.private_vpc_public_subnet_ids
  master_nodes = module.control_plane.master_nodes
  create_external_loadbalancer = var.create_external_loadbalancer
}
# ---------------------------
#      module.load_balancer.private_vpc_id
#      module.load_balancer.infrastructure_id
#      module.load_balancer.clustername
#      module.load_balancer.ocp_control_plane_lb_int_arn
#      module.load_balancer.ocp_control_plane_lb_int_6443_tg_arn
#      module.load_balancer.ocp_control_plane_lb_int_22623_tg_arn
# ---------------------------