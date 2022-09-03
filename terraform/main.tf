terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
      version = "1.35.1"
    }
  }
}

provider "hcloud" {
  token = var.cloud_api_token
}

data "hcloud_ssh_keys" "all_keys" {
}

data "hcloud_firewall" "firewall-1" {
  name = "firewall-1"
}

# resource "local_file" "userdata-yaml" {
#     content = templatefile("userdata.yaml.tmpl",
#         {
#             server-name = hcloud_server.avogadro.name
#             user-name = var.user_information.name
#             user-gecos = var.user_information.gecos
#             user-passwd = var.user_information.passwd
#         }
        
#     )
#     filename = "nocommit/userdata.yaml"
# }

# # File definition for user-data
# data "local_file" "userdata-yaml" {
#     filename = "nocommit/userdata.yaml"
# }

data "template_file" "userdata-yaml" {
  template =  <<EOF
  #cloud-config

########  Set Hostname
hostname: ${var.server_information.name}
write_files:
########  Permanently Disable ipv6 just incase it messes up NAT
########  Permanently set net.ipv4.ip_forward to enabled
  - path: /etc/crontab
    append: true
    content: |
      @reboot root /sbin/iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
  - path: /etc/sysctl.d/20-NAT.conf
    content: |
      net.ipv6.conf.all.disable_ipv6=1
      net.ipv6.conf.default.disable_ipv6=1
      net.ipv4.ip_forward=1
  - path: /etc/ssh/sshd_config
    content: |
      Subsystem sftp /usr/lib/openssh/sftp-server
      Port 4444
      PasswordAuthentication yes
      PermitEmptyPasswords no
      PermitRootLogin yes
      X11Forwarding yes
      Match User ${var.user_information.name},root
        PasswordAuthentication yes
runcmd:
  - sysctl -w net.ipv6.conf.all.disable_ipv6=1
  - sysctl -w net.ipv6.conf.default.disable_ipv6=1
  - sysctl -w net.ipv4.ip_forward=1

########  Package update and upgrade
package_update: true
package_upgrade: true
packages:
  - git
  - mosh
  - nmap
  - build-essential
  - openssl
  - curl
  - sqlite3
  - gcc
  - make
  - g++
  - dpkg-dev
  - htop
  - itop
  - iperf3
  - apt-transport-https
  - ca-certificates
  - gnupg-agent
  - software-properties-common
  - ansible
  - sshuttle

########  Users
users: 
  - name: root
    lock_passwd: false
  - name: ${var.user_information.name}
    gecos: ${var.user_information.gecos}
    primary_group: ${var.user_information.name}
    groups: users
    lock_passwd: false
    passwd: ${var.user_information.passwd}
    ssh-authorized-keys:
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
disable_root: false
ssh_pwauth: true
chpasswd:
  list: |
    root:${var.user_information.passwd}
  expire: False

########  Post-config tasks
final_message: "Instance up after $UPTIME seconds" 
power_state:
  timeout: 120
  message: Rebooting...
  mode: reboot
EOF
}

data "template_cloudinit_config" "userdata-yaml" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "nocommit/userdata.yaml"
    content_type = "text/cloud-config"
    content      = "${data.template_file.userdata-yaml.rendered}"
  }
}


resource "hcloud_network" "network" {
  name     = var.network_information.name
  ip_range = var.network_information.cidr
}

resource "hcloud_network_subnet" "network-subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = "eu-central"
  ip_range     = hcloud_network.network.ip_range
}

resource "hcloud_server" "avogadro" {
  name        = var.server_information.name
  server_type = "cx11"
  image       = "ubuntu-20.04"
  location    = "nbg1"
  ssh_keys    = data.hcloud_ssh_keys.all_keys.ssh_keys.*.name
  keep_disk    = false
  backups      = false
  user_data = data.template_cloudinit_config.userdata-yaml.rendered
  firewall_ids = [data.hcloud_firewall.firewall-1.id]


  network {
    network_id = hcloud_network.network.id
    ip         = var.server_information.ipv4_address
  }

    depends_on = [
      hcloud_network_subnet.network-subnet,
      data.hcloud_firewall.firewall-1
  ]
}

resource "hcloud_volume" "avogadro_datadisk_01" {
  name = "avogadro_datadisk_01"
  size = 10  
  server_id = hcloud_server.avogadro.id
  automount = false
  format = "ext4"
    depends_on = [
    hcloud_server.avogadro,
  ]
}