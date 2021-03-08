####### AWS Access and Region Details #############################
variable "aws_region" {
  default  = "eu-west-1"
}

variable "aws_azs" {
  type  = list(string)
  description = "The availability zone letter appendix you want to deploy to in the selected region "
  default = ["a", "b", "c"]
}

variable "default_tags" {
  default = {}
}

variable "infrastructure_id" {
  default = ""
}


variable "clustername" { default = "ocp4" }

# Subnet Details
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
variable "domain" { default = "" }
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
variable "ocp_vpc_id" { }
variable "ocp_pri_subnet_ids" { default = [] }
variable "ocp_pub_subnet_ids" { default = [] }
variable "create_ingress_in_public_dns" { }
variable "create_external_loadbalancer" { }

variable "bastion_ami" { }
variable "bastion_ssh_key_public" { }
variable "bastion_ip" { default = "" }
