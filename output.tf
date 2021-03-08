
output "clustername" {
    value =  var.clustername
}

# output "infrastructure_id" {
#     value =  local.infrastructure_id
# }

output "domain" {
    value =  var.domain
}

output "api" {
    value = "https://api.${var.clustername}.${var.domain}:6443"
}

output "kubeconfig" {
    value = "${abspath(path.root)}/kubeconfig"
}

output "kube-admin-password" {
    value = "${abspath(path.root)}/kubeadmin-password"
}

output "vpc_id" {
    value = var.ocp_vpc_id
}

output "ocp_pri_subnet_ids" {
    value = var.ocp_pri_subnet_ids
}
