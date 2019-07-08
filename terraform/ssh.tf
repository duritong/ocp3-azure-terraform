resource "tls_private_key" "bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "openshift" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "bastion_private_key" {
  sensitive_content = "${tls_private_key.bastion.private_key_pem}"
  filename          = "${path.module}/../ssh/bastion"

  provisioner "local-exec" {
    command = "chmod 0600 ${path.module}/../ssh/bastion"
    working_dir = "${path.module}"
  }
}
