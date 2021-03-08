
output "clustername" {
    value =  var.clustername
}

output "master_ign_64" {
    value =  base64encode(data.local_file.master_ign.content)
}

output "worker_ign_64" {
    value =  base64encode(data.local_file.worker_ign.content)
}

output "bootstrap_ip" {
    value =  aws_instance.bootstrap[*].private_ip
}
