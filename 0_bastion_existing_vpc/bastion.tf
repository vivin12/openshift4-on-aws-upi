resource "aws_eip" "bastion_eip" {
  vpc = true
}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
  // Use existing Elastic IP Allocation ID
  //allocation_id = "eipalloc-01e4606845082a97d"
}

data "aws_subnet" "ocp_pub_subnet" {
  count       =  length(var.ocp_pub_subnet_ids)
  id          = "${element(var.ocp_pub_subnet_ids, count.index)}"
}

data "aws_subnet" "ocp_pri_subnet" {
  count       =  length(var.ocp_pri_subnet_ids)
  id          = "${element(var.ocp_pri_subnet_ids, count.index)}"
}


resource "aws_instance" "bastion" {
  // https://access.redhat.com/articles/4297201
  // RHEL 7.6 ami
//ami  eu-central-1
//ami                         = "ami-0fc86555914f6a9f2"
//ami  eu-west-1
//  ami                         = "ami-04c89a19fea29f1f0"
// ami eu-north-1 RHEL 8
  ami                         = var.bastion_ami //"ami-0b149b24810ebb323"
  key_name                    = aws_key_pair.bastion_ssh_key.key_name
  instance_type               = "t3.medium"
  subnet_id                   = data.aws_subnet.ocp_pub_subnet.0.id
  vpc_security_group_ids      = ["${aws_security_group.bastion-sg.id}"]
  root_block_device {
      volume_type = "gp2"
      volume_size = 100
  }
  tags = {
      Name = "bastion-host"
  }
  user_data =<<EOT
#!/bin/bash
yum install -y unzip wget python38
ln -s /usr/bin/python3 /usr/bin/python
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
curl -LO https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip
unzip terraform_0.12.28_linux_amd64.zip -d /usr/local/bin
yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
yum install -y jq
ssh-keygen -t rsa -b 4096 -N "" -f /home/ec2-user/.ssh/id_rsa_aws_ocp
chown ec2-user: /home/ec2-user/.ssh/id_rsa_aws_ocp
chmod 600 /home/ec2-user/.ssh/id_rsa_aws_ocp
EOT

}

resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
  vpc_id = data.aws_vpc.ocp_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "bastion_ssh_key" {
  key_name   = "bastion-ssh-key"
  public_key = file(var.bastion_ssh_key_public)
}
