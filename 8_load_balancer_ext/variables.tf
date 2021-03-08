####### AWS Access and Region Details #############################
variable "aws_region" {
  default  = "us-east-2"
  description = "One of us-east-2, us-east-1, us-west-1, us-west-2, ap-south-1, ap-northeast-2, ap-southeast-1, ap-southeast-2, ap-northeast-1, us-west-2, eu-central-1, eu-west-1, eu-west-2, sa-east-1"
}

variable "default_tags" {
    default = {}
}

variable "infrastructure_id" { default = "" }

variable "clustername" { default = "ocp4" }

variable "private_vpc_id" {}

# Subnet Details
variable "private_vpc_private_subnet_ids" {
  description = "List of subnet ids"
  type        = list(string)
}

variable "private_vpc_public_subnet_ids" {
  description = "List of subnet ids"
  type        = list(string)
}

variable "create_external_loadbalancer" {
  default = false
}

variable "master_nodes" {
}

variable "domain" {
  default = ""
}

variable "aws_azs" {
  type  = list(string)
  description = "The availability zone letter appendix you want to deploy to in the selected region "
  default = ["a", "b", "c"]
}

variable "vpc_private_subnet_cidrs" {
  description = "List of subnet CIDRs"
  type        = list(string)
  default     = ["0.0.0.0/24", "0.0.0.0/24", "0.0.0.0/24" ]
}

variable "vpc_public_subnet_cidrs" {
  description = "List of subnet CIDRs"
  type        = list(string)
  default     = ["0.0.0.0/24", "0.0.0.0/24", "0.0.0.0/24" ]
}

variable "private_vpc_cidr" { default = "0.0.0.0/16" }
variable "ami" { default = "" }
variable "cluster_network_cidr" { default = "0.0.0.0/17" }
variable "cluster_network_host_prefix" { default = "23" }
variable "service_network_cidr" { default = "0.0.0.0/24" }
variable "bootstrap" { default = { type = "i3.xlarge"} }
variable "control_plane" { default = { count = "3", type = "m4.xlarge", disk = "120"} }
variable "worker" {        default = { count = "3", type = "m4.large",  disk = "120"} }
variable "openshift_pull_secret" { default = "./openshift_pull_secret.json" }
variable "use_worker_machinesets" { default = true }
variable "openshift_installer_url" { default = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest" }
variable "ocp_vpc_id" { default = "" }
variable "ocp_pri_subnet_ids" { default = [] }
variable "ocp_pub_subnet_ids" { default = [] }
variable "create_ingress_in_public_dns" { }

variable "bastion_ami" { default = "" }
variable "bastion_ssh_key_public" { default = "" }
variable "bastion_ip" { default = "" }
