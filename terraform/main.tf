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

# File definition for user-data
data "local_file" "user_data" {
    filename = "nocommit/userdata.yaml"
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
  user_data = file(data.local_file.user_data.filename)
  
  network {
    network_id = hcloud_network.network.id
    ip         = var.server_information.ip_address
  }

    depends_on = [
    hcloud_network_subnet.network-subnet,
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