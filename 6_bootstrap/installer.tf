locals {
  openshift_wget_dir = "${path.root}/openshift_wget_dir"
}

resource "null_resource" "openshift_installer" {
  provisioner "local-exec" {
    command = <<EOF
case $(uname -s) in
  Linux)
    wget -q -r -l1 -np -nd ${var.openshift_installer_url} -P ${local.openshift_wget_dir} -A 'openshift-install-linux-4*.tar.gz'
    ;;
  Darwin)
    wget -q -r -l1 -np -nd ${var.openshift_installer_url} -P ${local.openshift_wget_dir} -A 'openshift-install-mac-4*.tar.gz'
    ;;
  *) exit 1
    ;;
esac
EOF
  }

  provisioner "local-exec" {
    command = "tar zxvf ${local.openshift_wget_dir}/openshift-install-*-4*.tar.gz -C ${path.module}"
  }

}

resource "null_resource" "openshift_client" {
  depends_on = [
    null_resource.openshift_installer
  ]

  provisioner "local-exec" {
    command = <<EOF
case $(uname -s) in
  Linux)
    wget -q -r -l1 -np -nd ${var.openshift_installer_url} -P ${local.openshift_wget_dir} -A 'openshift-client-linux-4*.tar.gz'
    ;;
  Darwin)
    wget -q -r -l1 -np -nd ${var.openshift_installer_url} -P ${local.openshift_wget_dir} -A 'openshift-client-mac-4*.tar.gz'
    ;;
  *)
    exit 1
    ;;
esac
EOF
  }

  provisioner "local-exec" {
    command = "tar zxvf ${local.openshift_wget_dir}/openshift-client-*-4*.tar.gz -C ${path.module}"
  }

  provisioner "local-exec" {
    command = "sudo tar zxvf ${local.openshift_wget_dir}/openshift-client-*-4*.tar.gz -C /usr/local/bin --exclude README.md"
  }
  
  provisioner "local-exec" {
    command = "rm -rf ${local.openshift_wget_dir}"
  }
}

data "template_file" "install_config_yaml" {
  template = <<-EOF
apiVersion: v1
baseDomain: ${var.domain}
compute:
- hyperthreading: Enabled
  name: worker
  replicas: ${lookup(var.worker, "count", 3)}
controlPlane:
  hyperthreading: Enabled
  name: master
  replicas: ${lookup(var.control_plane, "count", 3)}
metadata:
  name: ${var.clustername}
networking:
  clusterNetworks:
  - cidr: ${var.cluster_network_cidr}
    hostPrefix: ${var.cluster_network_host_prefix}
  machineCIDR:  ${data.aws_vpc.ocp_vpc.cidr_block}
  networkType: OpenShiftSDN
  serviceNetwork:
  - ${var.service_network_cidr}
platform:
  aws:
    region: ${data.aws_region.current.name}
pullSecret: '${file(var.openshift_pull_secret)}'
sshKey: '${chomp(file(var.core_ssh_public_key))}'
EOF
}

resource "local_file" "install_config" {
  content  =  data.template_file.install_config_yaml.rendered
  filename =  "${path.module}/install-config.yaml"
}

resource "null_resource" "generate_manifests" {
  triggers = {
    install_config =  data.template_file.install_config_yaml.rendered
  }

  depends_on = [
    local_file.install_config,
    null_resource.openshift_installer
  ]

  provisioner "local-exec" {
    command = "rm -rf ${path.module}/temp"
  }

  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/temp"
  }

  provisioner "local-exec" {
    command = "cp ${path.module}/install-config.yaml ${path.module}/temp"
  }

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/temp create manifests"
  }
}

# because we're providing our own control plane machines, remove it from the installer
resource "null_resource" "manifest_cleanup_control_plane_machineset" {
  depends_on = [
    null_resource.generate_manifests
  ]

  triggers = {
    install_config =  data.template_file.install_config_yaml.rendered
    local_file     =  local_file.install_config.id
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/temp/openshift/99_openshift-cluster-api_master-machines-*.yaml"
  }
}

# remove these machinesets, we will rewrite them using the security group and subnets that we created
resource "null_resource" "manifest_cleanup_worker_machineset" {
  depends_on = [
    null_resource.generate_manifests
  ]

  triggers = {
    install_config =  data.template_file.install_config_yaml.rendered
    local_file     =  local_file.install_config.id
  }

  provisioner "local-exec" {
    command = "rm -f ${path.module}/temp/openshift/99_openshift-cluster-api_worker-machines*.yaml"
  }
}

# remove public DNS domain management, just manage the private hosted zone
resource "local_file" "cluster_dns_config" {
  depends_on = [
    null_resource.generate_manifests
  ]
  file_permission = "0644"
  filename        =  "${path.module}/temp/manifests/cluster-dns-02-config.yml"

  content = <<EOF
apiVersion: config.openshift.io/v1
kind: DNS
metadata:
  creationTimestamp: null
  name: cluster
spec:
  baseDomain: ${var.clustername}.${var.domain}
  privateZone:
    id: ${data.aws_route53_zone.ocp_private.zone_id}
%{ if var.create_ingress_in_public_dns != false ~}
  publicZone:
    id: ${data.aws_route53_zone.ocp_public.zone_id}
%{ endif ~}
status: {}
EOF
}

# build the bootstrap ignition config
resource "null_resource" "generate_ignition_config" {
  depends_on = [
    null_resource.manifest_cleanup_control_plane_machineset,
    null_resource.manifest_cleanup_worker_machineset,
    //local_file.worker_machineset,
    //local_file.cluster_infrastructure_config,
    local_file.cluster_dns_config,
  ]

  triggers = {
    install_config                   =  data.template_file.install_config_yaml.rendered
    local_file_install_config        =  local_file.install_config.id
    //local_file_infrastructure_config =  local_file.cluster_infrastructure_config.id
    local_file_dns_config            =  local_file.cluster_dns_config.id
    //local_file_worker_machineset     = "${join(",", local_file.worker_machineset.*.id)}"
  }

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/temp create ignition-configs"
  }
}

resource "null_resource" "cleanup" {
  depends_on = [
    aws_instance.bootstrap,
    aws_s3_bucket_object.bootstrap_ign
  ]

  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf ${path.module}/temp"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ${path.module}/openshift-install"
  }

}

data "local_file" "bootstrap_ign" {
  depends_on = [
    null_resource.generate_ignition_config
  ]

  filename =  "${path.module}/temp/bootstrap.ign"
}

data "local_file" "master_ign" {
  depends_on = [
    null_resource.generate_ignition_config
  ]

  filename =  "${path.module}/temp/master.ign"
}

data "local_file" "worker_ign" {
  depends_on = [
    null_resource.generate_ignition_config
  ]

  filename =  "${path.module}/temp/worker.ign"
}

resource "null_resource" "get_auth_config" {
  depends_on = [null_resource.generate_ignition_config]
  provisioner "local-exec" {
    when    = create
    command = "cp ${path.module}/temp/auth/* ${path.root}/ "
  }
  provisioner "local-exec" {
    when    = create
    command = "echo export KUBECONFIG=${abspath(path.root)}/kubeconfig >> ~/.bashrc"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm ${path.root}/kubeconfig ${path.root}/kubeadmin-password "
  }
}
