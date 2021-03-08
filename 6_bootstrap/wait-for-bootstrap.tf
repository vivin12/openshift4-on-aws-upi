resource "null_resource" "wait_for_bootstrap" {

  depends_on = [
    aws_instance.bootstrap
  ]

  provisioner "local-exec" {
    command = "${path.module}/openshift-install --dir=${path.module}/temp wait-for bootstrap-complete"
  }

}
