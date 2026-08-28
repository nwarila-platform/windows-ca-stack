# =========================================================================================== #
# File: 'terraform/aws.tfvars'
# --- [ Description ] ----------------------------------------------------------------------- #
#
# Variable input for the pinned aws-terraform-framework (SHA in .github/terraform-framework-pin).
# Plain tfvars — the workflow passes this file to terraform verbatim. This repository declares
# NO .tf files of its own: resources live in the pinned framework, configuration in the pinned
# ansible-framework plus this repository's roles.
#
# REACHABILITY — DIRECT SSH OVER A PUBLIC IPv4. The workflow discovers the runner's public IPv4
# and passes it as the framework's runtime-only runner_ip variable. When an operator hostname is
# configured it resolves that too and passes debug_ip, which adds RDP for a person working on the
# host. The framework attaches one security group carrying both to every interface. The instance
# receives a public IPv4 at launch; no Elastic IP is involved. The account has no NAT and no VPC
# endpoints.
#
# The dependency worth knowing: MapPublicIpOnLaunch is an attribute of a shared subnet no
# repository owns. Direct SSH requires the instance's launch-time public address as well as the
# runner-scoped security group.
#
# readiness_gate is FALSE by design: the playbook owns the bounded direct-SSH readiness check.
# The OpenSSH DefaultShell boots as cmd; the playbook's bootstrap play flips it to PowerShell on
# first contact, and every play after that declares the PowerShell shell type.
#
# =========================================================================================== #

# environment and the deployment identity (repository, repository_id, commit_sha, run_id) are
# deliberately NOT in this file: the workflow passes them as -var flags placed AFTER this file on
# the command line. Terraform resolves repeated command-line assignments in the order given, so it
# is that ordering, not the kind of flag, that keeps this file from renaming the deployment.

all_systems = [
  {
    region = "us_east_1"
    # NetBIOS caps a Windows hostname at 15 characters, so the hostname carries the short
    # form while the Function tag below carries the full repository identity.
    hostname = "tcnaw-ca01"
    # The ratified availability-zone spec lock, and a subnet in this account's only VPC.
    availability_zone = "us-east-1c"
    subnet_id         = "subnet-03a855e712be7b399"
    # The framework CONSUMES key pairs and never creates them, so this names the standing
    # account key pair. user_data installs its public half by reading IMDS; the private half
    # lives only in the AWS_EC2_SSH_PRIVATE_KEY organization secret and the runner's
    # temporary directory.
    key_name = "nwarila-ec2-key"
    # The org EC2 baseline plus read-only access to the application repository bucket, which is
    # what lets this host pull its own installers down rather than receiving them from the
    # controller. The runner role only reads and passes whichever profile is named here.
    iam_instance_profile = "nwarila-ec2-apprepo-profile"
    aws_kms_alias        = "aws/ebs"
    # Windows_Server-2025-English-STIG-Full, owner 801119661308 — accepted from the
    # framework's vendor allowlist, the same hardened base the golden deploy uses.
    ami = "ami-04807a1de3f592cc5"
    # No standalone data volumes yet, so the OS instance is not swap-eligible; a future
    # persistent deployment declares its data volumes below and flips this to true.
    refresh = false
    # Starting size for the application proof; resize when the CA stack's real footprint
    # is measured.
    instance_type = "t3.medium"
    # Direct SSH reaches the launch-time public IPv4 through the runner-scoped framework SG.
    connection_type = "ssh"
    readiness_user  = null

    readiness_gate             = false
    readiness_command          = null
    readiness_script_dir       = null
    readiness_private_key_path = null
    imds_hop_limit             = 1
    set_state                  = null

    tags = {
      Function = "windows-ca-stack"
      Backup   = false
    }

    root_block_device = {
      delete_on_termination = true
      iops                  = null
      tags                  = {}
      throughput            = null
      volume_type           = "gp3"
      # The AMI's native size; certificate authority state is small and lives on the root
      # until a persistent deployment declares its own data volume.
      volume_size = "30"
    }

    ebs_block_devices = []

    ami_block_device_overrides = []

    network_interfaces = [
      {
        description     = "tcnaw-ca01 CI firewall"
        interface_type  = null
        private_ip      = null
        security_groups = []
        ingress         = []
        egress = [
          {
            description                  = "HTTPS out"
            ip_protocol                  = "tcp"
            from_port                    = 443
            to_port                      = 443
            cidr_ipv4                    = "0.0.0.0/0"
            prefix_list_id               = null
            referenced_security_group_id = null
          },
          # The VPN tunnel that carries the host onto the private network. Scoped by port rather
          # than by address: the profile names its endpoint by DNS, and that address changes.
          {
            description                  = "OpenVPN tunnel out"
            ip_protocol                  = "udp"
            from_port                    = 1194
            to_port                      = 1194
            cidr_ipv4                    = "0.0.0.0/0"
            prefix_list_id               = null
            referenced_security_group_id = null
          }
        ]
        tags = {}
      }
    ]

    # No Elastic IP: the subnet auto-assigns the launch-time public IPv4 used for direct SSH.
    associate_public_ip = false
  }
]

all_databases      = []
all_load_balancers = []
