# Automated OpenShift v4 upi installation on AWS using Terraform

This project automates the Red Hat OpenShift Container Platform 4.x installation on Amazon AWS platform. It focuses on the OpenShift User-provided infrastructure installation (UPI) where end users provide pre-existing infrastructure including VMs, networking, load balancers, DNS configuration etc.

* [Infrastructure Architecture](#infrastructure-architecture)
* [Terraform Automation](#terraform-automation)
* [Installation Procedure](#installation-procedure)
* [Cluster access](#cluster-access)
* [AWS Cloud Provider](#aws-cloud-provider)


## Infrastructure Architecture

For detail on OpenShift UPI, please reference the following:


* [https://docs.openshift.com/container-platform/4.2/installing/installing_aws_user_infra/installing-aws-user-infra.html](https://docs.openshift.com/container-platform/4.1/installing/installing_aws_user_infra/installing-aws-user-infra.html)
* [https://github.com/openshift/installer/blob/master/docs/user/aws/install_upi.md](https://github.com/openshift/installer/blob/master/docs/user/aws/install_upi.md)

The provided Terraform scripts are based on this github repository but have been modified to also create a bastion host.

https://github.com/ibm-cloud-architecture/terraform-openshift4-aws

The scripts are intended to run in two parts. The first part in the `0_bastion` directory is supposed to run from a local computer and does create a VPC, subnets and a bastion host in AWS.

If an existing VPC and subnets should be used, the run terrafom with the `0_bastion_existing_vpc` directory to create a bastion host in a predefined VPC.

The second part with all remaining directories are supposed to being run from the bastion host.

## Terraform Automation

This project uses mainly Terraform as infrastructure management and installation automation driver. All the user provisioned resources are created via the terraform scripts in this project.

### Prerequisites

1. To use Terraform automation, download the Terraform binaries [here](https://www.terraform.io/downloads.html). The code here has been tested on Terraform 0.12.28.

   On MacOS

   ```bash
   curl -LO https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_darwin_amd64.zip
   sudo unzip terraform_0.12.28_darwin_amd64.zip -d /usr/local/bin
   ```

   On Linux
   ```bash
   curl -LO https://releases.hashicorp.com/terraform/0.12.28/terraform_0.12.28_linux_amd64.zip
   sudo unzip terraform_0.12.28_linux_amd64.zip -d /usr/local/bin
   ```

   We recommend to run Terraform automation from an AWS bastion host because the installation will place the entire OpenShift cluster in a private network where you might not have easy access to validate the cluster installation from your laptop.


1. Get the Terraform code

   ```bash
   git clone https://github.ibm.com/Martin-Caesar/install-openshift4-on-aws-upi.git
   ```

2. Prepare the DNS

   OpenShift requires a valid DNS domain, you can get one from AWS Route53 or using existing domain and registrar. The DNS must be registered as a Public Hosted Zone in Route53.


3. Prepare AWS Account Access

   https://docs.aws.amazon.com/cli/latest/userguide/install-bundle.html

   AWS CLI v1 requires python 2.7 or python 3.4

   Installation on macOS and Linux

   ```bash
   curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
   unzip awscli-bundle.zip
   sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
   ```

   Configure AWS CLI

   ```bash
   $ aws configure
   AWS Access Key ID [None]: AKIAIOSFODNN7EXAMPLE
   AWS Secret Access Key [None]: wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   Default region name [None]: eu-central-1
   Default output format [None]: json
   ```

   It is also possible to source environment variables with Access Key and Secret.

   ```
   export AWS_ACCESS_KEY_ID="AKIAIOSFODNN7EXAMPLE"
   export AWS_SECRET_ACCESS_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
   export AWS_DEFAULT_REGION="eu-central-1"
   ```

   Please reference the [Required AWS Infrastructure components](https://docs.openshift.com/container-platform/4.2/installing/installing_aws_user_infra/installing-aws-user-infra.html#installation-aws-user-infra-requirements_installing-aws-user-infra) to setup your AWS account before installing OpenShift 4.

   We suggest to create an AWS IAM user dedicated for OpenShift installation with permissions documented above.

   Important: Run `aws configure` before running the Terraform scripts.

## Installation Procedure

This project installs the OpenShift 4 in several stages where each stage automates the provisioning of different components from infrastructure to OpenShift installation. The design is to provide the flexibility of different topology and infrastructure requirement.

1. The deployment assumes that you run the terraform deployment from a Linux based environment. This can be performed on an AWS-linux EC2 instance (bastion host). The deployment machine has the following requirements:

    - terraform 0.12 or later
    - aws client
    - jq command
    - wget command

2. Provision an EC2 bastion instance (with public and private subnets).

   Note: The Terraform scripts in this codes also installs the oc cli and aws cli on the bastion host. The aws cli is installed from a user_data script when the bastion host is created. Also Terraform is installed from the user_data. The oc cli is installed during the OpenShift installation.

   Manual step to install OpenShift command line `oc` cli (done in Terraform script):

   ```bash
   wget -q -r -l1 -nd -np -P ./temp_wget_dir -A 'openshift-client-linux-4*.tar.gz' https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest

   sudo tar xf temp_wget_dir/openshift-client-linux-4.*.tar.gz -C /usr/local/bin --exclude README.md
   rm -rf temp_wget_dir/

   oc version
   ```

   Note: Use this url for OpenShift 4.4 version. https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.4

   If a specific OpenShift version is need, for example 4.4.6, then use the url https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.4.6

   You'll also need the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-bundle.html) to do this.

   Deploy the private network and OpenShift 4 cluster through the connection using transit gateway to the public environment.
   You can use all the automation in a single deployment or you can use the individual folders in the git repository sequentially. The folders are:

  - 0_bastion: Create the VPC and subnets for the OpenShift cluster. Also create a bastion host.
  - 0_bastion_existing_vpc: Create bastion host into existing VPC and subnets.
  - 2_load_balancer: Create the system loadbalancer for the API and machine config operator
  - 3_dns: generate a private hosted zone using route 53
  - 4_security_group: defines network access rules for masters and workers
  - 5_iam: define AWS authorities for the masters and workers
  - 6_bootstrap: main module to provision the bootstrap node and generates OpenShift installation files and resources
  - 7_control_plane: create master nodes manually (UPI)
  - 8_load_balancer_ext: Optional create external load balancer.

	You can also provision all the components in a single terraform main module, to do that, you need to use a `terraform.tfvars`, that is copied from the `terraform.tfvars.example` file. The variables related to that are:

	Create a `terraform.tfvars` file with following content:

  ```
  aws_region = "eu-west-1"
  aws_azs = ["a", "b", "c"]
  default_tags = { "owner" = "ocp44" }
  clustername = "ocp42"
  domain = "example.com"
  create_ingress_in_public_dns = true
  create_external_loadbalancer = true
  ami = "ami-0bc59aaa7363b805d"
  bastion_ami = "ami-0b149b24810ebb323"
  bastion_ssh_key_public = "~/.ssh/id_rsa_aws_ocp.pub"
  bootstrap = { type = "i3.xlarge" }
  control_plane = { count = "3" , type = "m5.xlarge", disk = "120" }
  worker        = { count = "3" , type = "m5.xlarge" , disk = "120" }
  openshift_pull_secret = "./openshift_pull_secret.json"
  openshift_installer_url = "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.4"
  ```

|name | required | description and value        |
|----------------|------------|--------------|
| `aws_region`   | no           | AWS region that the VPC will be created in.  By default, uses `eu-west-1`.  Note that for an HA installation, the AWS selected region should have at least 3 availability zones. |
| `aws_azs`          | no           | AWS Availability Zones that the VPC will be created in, e.g. `[ "a", "b", "c"]` to install in three availability zones.  By default, uses `["a", "b", "c"]`.  Note that the AWS selected region should have at least 3 availability zones for high availability.  Setting to a single availability zone will disable high availability and not provision EFS, in this case, reduce the number of master and proxy nodes to 1. |
| `default_tags`     | no          | AWS tag to identify a resource for example owner:gchen     |
| `clustername`     | yes          | The name of the OpenShift cluster you will install     |
| `domain` | yes | The domain that has been created in Route53 public hosted zone |
| `create_ingress_in_public_dns` | no | if true then ingress will create `*.apps` entry in public DNS zone |
| `create_external_loadbalancer` | no | if true then an external load balancer is created |
| `ami` | no | Red Hat CoreOS ami for your region (see [here](https://docs.openshift.com/container-platform/4.4/installing/installing_aws_user_infra/installing-aws-user-infra.html#installation-aws-user-infra-rhcos-ami_installing-aws-user-infra)). Other platforms images information can be found [here](https://github.com/openshift/installer/blob/master/data/data/rhcos.json) |
| `bootstrap` | no | |
| `control_plane` | no | |
| `worker` | no | this variable is used to size the worker machines |
| `openshift_pull_secret` | no | The value refers to a file name that contain downloaded pull secret from https://cloud.redhat.com/openshift/install; the default name is `openshift_pull_secret.json` |
| `openshift_installer_url` | no | The [URL](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest-4.4) to the download site for Red Hat OpenShift installation and client codes.  |
| `private_vpc_cidr`     | no          | VPC private netwrok CIDR range default 0.0.0.0/16  |
| `vpc_private_subnet_cidrs`     | no          | CIDR range for the VPC private subnets default ["0.0.0.0/24", "10.10.11.0/24", "10.10.12.0/24" ]   |
| `vpc_public_subnet_cidrs` | no | default to ["0.0.0.0/24","0.0.0.0/24","0.0.0.0/24"] |
| `cluster_network_cidr` | no | The pod network CIDR, default to "0.0.0.0/17" |
| `cluster_network_host_prefix` | no | The prefix for the pod network, default to "23" |
| `service_network_cidr` | no | The service network CIDR, default to "0.0.0.0/24" |



See [Terraform documentation](https://www.terraform.io/intro/getting-started/variables.html) for the format of this file.

Note: If you want the ingress controller to create an `*.apps` entry in the public DNS zone, then set `create_ingress_in_public_dns = true` in the variables.

Generate ssh private key and public

```bash
ssh-keygen -t rsa -b 4096 -N '' -f ~/.ssh/id_rsa_aws_ocp
```

Note: This ssh key is used to access the bastion host. The terraform script does create a new ssh key on the bastion host that is included in the install-config.yaml file.

Initialize the Terraform:

Create bastion host.

```bash
cd install-openshift4-on-aws-upi
terraform init
terraform apply --state=0_bastion/terraform.state --auto-approve 0_bastion/
```

Note: If the VPC and subnets already exists, the use `0_bastion_existing_vpc` directory.

```
terraform apply --state=0_bastion_existing_vpc/terraform.state --auto-approve 0_bastion_existing_vpc/
```

```shell
Apply complete! Resources: 47 added, 0 changed, 0 destroyed.

Outputs:

bastion_elastic_ip = 13.49.94.111
clustername = ocp44-cp4i
infrastructure_id = ocp44-cp4i-ypztt
private_vpc_id = vpc-04ca89b1b81c182fb
private_vpc_private_subnet_ids = [
  "subnet-0000b4288f6266d25",
  "subnet-0b31354b3f1b9cf70",
  "subnet-04877d9cf554e0af4",
]
private_vpc_public_subnet_ids = [
  "subnet-0d6b893da98b71c04",
  "subnet-06811a09f380fd91f",
  "subnet-0d8d19514e9582a5f",
]
```

Note: The terrafom scripts creates a file `bastion-output.auto.tfvars` with the output variables that contains the VPC id and subnets id. The next `terraform apply` will read the variables from this file.

Copy all terraform scripts to bastion host and continue OpenShift installation from bastion host.

```bash
IP=13.49.94.111
SSH_KEY=~/.ssh/id_rsa_aws_ocp
rsync -a -e "ssh -i ${SSH_KEY}" --exclude ".*" ./ ec2-user@${IP}:install-openshift4-on-aws-upi/
```

Important: Create the `openshift_pull_secret.json` file in the `install-openshift4-on-aws-upi` directory. The pull secret is obtained from https://cloud.redhat.com/openshift/install and requires a valid OpenShift subscription.

Run the terraform provisioning on bastion host:

```
ssh -i ${SSH_KEY} ec2-user@${IP}
```

Configure aws cli access key.

```
aws configure
```

Check aws cli

```
aws iam get-user
```

Run terrafom to install OpenShift cluster.

```bash
cd install-openshift4-on-aws-upi
terraform init
terraform apply --auto-approve
```

Remove bootstrap

```bash
terraform destroy --auto-approve -target=module.bootstrap.aws_instance.bootstrap
```

Run oc commands

```bash
export KUBECONFIG=~/install-openshift4-on-aws-upi/kubeconfig

oc get nodes
```

Approve certificates.

```
oc get csr

oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs oc adm certificate approve
```

Check if worker nodes are ready. Repeat step for certificate approve if a worker node is missing or if new pending csr appears.

```
oc get csr

oc get nodes -l node-role.kubernetes.io/worker
```

Wait until cluster installation is complete and all clusteroperator are available.

```
oc get clusteroperator

oc get clusterversion

oc whoami --show-server

oc whoami --show-console
```

## Uninstalling Openshift

The uninstall is also a two step procedure.

On the bastion host, run the first step to uninstall all AWS resources except the bastion host, subnets and VPC.

```bash
terraform destroy --auto-approve
```

The second step removes the bastion host and the remaining resources including the VPC. Before the VPC can be deleted, some other resources like ELB and Security Groups needs to be deleted manually if they have been created by OpenShift.

For example the classic loadbalancer, that the ingress controller has created, must be manually deleted together with the security group for that loadbalancer.

Then run on a local computer the `terraform destroy` for the `0_bastion` directory or `0_bastion_existing_vpc` directory.

```bash
terraform destroy --state=0_bastion/terraform.state --auto-approve 0_bastion/
```

## Troubleshooting AWS

List instances

```shell
aws ec2 describe-instances --query "Reservations[*].Instances[*].[Placement.AvailabilityZone,InstanceId,VpcId,PublicIpAddress,State.Name,Tags[?Key=='Name']|[0].Value]" --output table
```

```
vpc="vpc-xxxxxxxxxxxxx"

aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=${vpc} \
--query "NetworkInterfaces[*].[NetworkInterfaceId,Description,VpcId,PrivateIpAddress]" \
--output table
```

Error when deleting VPC during cleanup, then manually delete the following:

Delete VPC > Endpoint Service

Delete EC2 > Load Balancers
Delete EC2 > Target Groups
Delete EC2 > Security Groups

Find the remaining resources in the VPC using the following commands. Then delete the resources that are preventing the VPC from being deleted.

https://aws.amazon.com/de/premiumsupport/knowledge-center/troubleshoot-dependency-error-delete-vpc/

```bash
#!/bin/bash
vpc="vpc-xxxxxxxxxxxxx"
aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep InternetGatewayId
aws ec2 describe-subnets --filters 'Name=vpc-id,Values='$vpc | grep SubnetId
aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$vpc | grep RouteTableId
aws ec2 describe-network-acls --filters 'Name=vpc-id,Values='$vpc | grep NetworkAclId
aws ec2 describe-vpc-peering-connections --filters 'Name=requester-vpc-info.vpc-id,Values='$vpc | grep VpcPeeringConnectionId
aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values='$vpc | grep VpcEndpointId
aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$vpc | grep NatGatewayId
aws ec2 describe-security-groups --filters 'Name=vpc-id,Values='$vpc | grep GroupId
aws ec2 describe-instances --filters 'Name=vpc-id,Values='$vpc | grep InstanceId
aws ec2 describe-vpn-connections --filters 'Name=vpc-id,Values='$vpc | grep VpnConnectionId
aws ec2 describe-vpn-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep VpnGatewayId
aws ec2 describe-network-interfaces --filters 'Name=vpc-id,Values='$vpc | grep NetworkInterfaceId
```

## Create AWS tags

Important: If subnets have been manually created, then a tag with infrastructure_id must be assigned to each subnet. Otherwise the IngressController cannot create a load balancer.

```
aws ec2 create-tags --resources subnet-039d644eabceb9703 --tags Key=kubernetes.io/cluster/ocp-cp4i-tdilf,Value=owned

for i in subnet-095cfa2ac3e370b4d subnet-0292072bd4f921896 subnet-0958bcf5188843532 subnet-0ec0d8703fc535059 subnet-004edfc19173f6d6e; do aws ec2 create-tags --resources ${i} --tags Key=kubernetes.io/cluster/ocp-cp4i-tdilf,Value=owned; done

```

Optional: delete tags before reinstalling.

```
aws ec2 delete-tags --resources subnet-039d644eabceb9703 --tags Key=kubernetes.io/cluster/ocp-cp4i-tdilf,Value=owned

for i in subnet-095cfa2ac3e370b4d subnet-0292072bd4f921896 subnet-0958bcf5188843532 subnet-0ec0d8703fc535059 subnet-004edfc19173f6d6e; do aws ec2 delete-tags --resources ${i} --tags Key=kubernetes.io/cluster/ocp-cp4i-tdilf,Value=owned; done
```

## Configure external and internal ingress

https://docs.openshift.com/container-platform/4.4/installing/install_config/configuring-private-cluster.html

The OpenShift IngressController in the default configuration creates an external load balancer. This is also true even when the DNS configuration is using the private zone only.

Example DNS config with private zone only.

Note: The variable `create_ingress_in_public_dns = true` does also add a public zone to the DNS config.

```
oc get dns cluster -o yaml

apiVersion: config.openshift.io/v1
kind: DNS
metadata:
  name: cluster
  ...
spec:
  baseDomain: ocp44.example.com
  privateZone:
    id: Z04383041G5FJ4KKBVHXF
```

The DNS names are only available on the private network on the bastion host, but the IP address resolves to an external address.

```
curl -k -i https://console-openshift-console.apps.ocp44-cp4i.cluster.aws.de -o /dev/null -s -v 2>&1 | head -2
* Rebuilt URL to: https://console-openshift-console.apps.ocp44-cp4i.cluster.aws.de/
*   Trying 0.0.0.0...
```

Setting IngressController to private

https://docs.openshift.com/container-platform/4.4/installing/install_config/configuring-private-cluster.html#private-clusters-setting-ingress-private_configuring-private-cluster

```
oc replace --force --wait --filename - <<EOF
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
  namespace: openshift-ingress-operator
  name: default
spec:
  endpointPublishingStrategy:
    type: LoadBalancerService
    loadBalancer:
      scope: Internal
EOF
```

Check DNS name again. The IP address resolves to an internal address.

```
curl -k -i https://console-openshift-console.apps.ocp44-cp4i.cluster.aws.de -o /dev/null -s -v 2>&1 | head -2
* Rebuilt URL to: https://console-openshift-console.apps.ocp44-cp4i.cluster.aws.de/
*   Trying 0.0.0.0...
```

Optional: Create second IngressController on external network.

```
DOMAIN=pub-apps.ocp44-cp4i.cluster.aws.de

cat << EOF > ingress-external.yaml
apiVersion: operator.openshift.io/v1
kind: IngressController
metadata:
 namespace: openshift-ingress-operator
 name: ingress-operator-external
spec:
 domain: ${DOMAIN}
 endpointPublishingStrategy:
  type: LoadBalancerService
  loadBalancer:
   scope: External
EOF
```

```
oc apply -f ingress-external.yaml
```

```
oc get IngressController -n openshift-ingress-operator
NAME                        AGE
default                     10m
ingress-operator-external   22s
```

Optional: If external dns is needed on ingress, then manually add DNS entry to public zone in Route53 in base domain.

In `cluster.aws.de` domain.

```
*.apps.ocp44-cp4i.cluster.aws.de type A, alias target is the external load balancer.
```

```
oc -n openshift-ingress get service
NAME                                        TYPE           CLUSTER-IP      EXTERNAL-IP                                                                         PORT(S)                      AGE
router-default                              LoadBalancer   0.0.0.0   internal-a8a1962d9340841828a129d7c9d04240-2067436434.elb.amazonaws.com   80:30857/TCP,443:30551/TCP   132m
router-ingress-operator-external            LoadBalancer   0.0.0.0   ac755d8b8c3b74e049c105c3c782f4c6-1416182892.elb.amazonaws.com            80:31376/TCP,443:32085/TCP   82m
router-internal-default                     ClusterIP      0.0.0.0   <none>                                                                              80/TCP,443/TCP,1936/TCP      132m
router-internal-ingress-operator-external   ClusterIP      0.0.0.0   <none>                                                                              80/TCP,443/TCP,1936/TCP      82m
```

Add external DNS in Route53.

Find load balancer zone id.

```
aws elb describe-load-balancers \
--query "LoadBalancerDescriptions[*].[DNSName,CanonicalHostedZoneNameID]" \
--output table
```

```
---------------------------------------------------------------------------------------------------------
|                                         DescribeLoadBalancers                                         |
+-------------------------------------------------------------------------------------+-----------------+
|  internal-a8a1962d9340841828a129d7c9d04240-2067436434.elb.amazonaws.com  |  Z23TAZ6LKFMNIO |
|  ac755d8b8c3b74e049c105c3c782f4c6-1416182892.elb.amazonaws.com           |  Z23TAZ6LKFMNIO |
+-------------------------------------------------------------------------------------+-----------------+
```

Find DNS hosted zone.

```
aws route53 list-hosted-zones --query "HostedZones[*].[Id,Name,ResourceRecordSetCount,Config.Comment,Config.PrivateZone]" --output table
```

Create alias record.

```
aws route53 change-resource-record-sets --hosted-zone-id "${YOUR_PUBLIC_ZONE}" --change-batch '{
   "Changes": [
     {
       "Action": "CREATE",
       "ResourceRecordSet": {
         "Name": "\\052.apps.ocp44-cp4i.cluster.aws.de",
         "Type": "A",
         "AliasTarget":{
           "HostedZoneId": "Z23TAZ6LKFMNIO",
           "DNSName": "ac755d8b8c3b74e049c105c3c782f4c6-1416182892.elb.amazonaws.com.",
           "EvaluateTargetHealth": false
         }
       }
     }
   ]
}'
```


## Create external load balancer after OpenShift cluster installation

This step creates an external load balancer that forwards traffic on port 6443 to the master nodes.

The terraform scripts omits the external load balancer if the variable `create_external_loadbalancer = false` is set.

Get master aws_instance id.

```
aws ec2 describe-instances \
--query "Reservations[*].Instances[*].[InstanceId,Tags[?Key=='Name']|[0].Value]" \
--output text | grep master | awk '{ print "\"" $1 "\"" "," }'
```

Create input variables in file `loadbalancer-input.auto.tfvars`, include master_nodes id and private subnets id.

```
private_vpc_id = "vpc-0a246badebe4c66bf"

master_nodes = [
  "i-0e2de04986945438a",
  "i-0d756cb920d9f9fe4",
  "i-01c4d263554503708",
]

private_vpc_private_subnet_ids = [
  "subnet-0893beb997e87d864",
  "subnet-04e3d96f2207518c5",
  "subnet-049e9111b6957b519",
]

private_vpc_public_subnet_ids = [
  "subnet-02b7b69b119dd51e1",
  "subnet-0a8ef94bf327f9716",
  "subnet-0d1ad32d18aeefbbb",
]

create_external_loadbalancer = true
```

```
terraform apply --state=8_load_balancer_ext/terraform.state --auto-approve 8_load_balancer_ext/
```

The OpenShift API is now available on both the external and internal network.

On the bastion host.

```
curl https://api.ocp44-cp4i.cluster.aws:6443/readyz -k -s -v 2>&1 | head -1
*   Trying 0.0.0.0...
```

From the internet.

```
curl https://api.ocp44-cp4i.cluster.aws:6443/readyz -k -s -v 2>&1 | head -1
*   Trying 0.0.0.0...
```

Optional if uninstall external load balancer.

```
terraform destroy --state=8_load_balancer_ext/terraform.state --auto-approve 8_load_balancer_ext/
```
