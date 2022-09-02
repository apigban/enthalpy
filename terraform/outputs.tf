### The Ansible inventory file
resource "local_file" "AnsibleInventory" {
    content = templatefile("inventory.tmpl",
        {
            server-name = hcloud_server.avogadro.name
            avogadro-ipv4 = hcloud_server.avogadro.ipv4_address
            avogadro-ipv6 = hcloud_server.avogadro.ipv6_address

            avogadro-disk-id = hcloud_volume.avogadro_datadisk_01.id
            avogadro-disk-name = hcloud_volume.avogadro_datadisk_01.name
            avogadro-disk-fspath = hcloud_volume.avogadro_datadisk_01.linux_device
         
        }
        
    )
    filename = "../ansible/host_vars/avogadro01.yaml"
    depends_on = [ hcloud_server.avogadro,
                    hcloud_volume.avogadro_datadisk_01 ]
}

resource "time_sleep" "wait_180_seconds" {
  depends_on = [local_file.AnsibleInventory]
  create_duration = "180s"
}

# resource "null_resource" "avogadro-ready" {
# # # Wait for instance to be ready
# #     provisioner "remote-exec" {
# #         connection {
# #             type     = "ssh"
# #             host     = hcloud_server.avogadro.ipv4_address
# #             user     = "${var.user_information.name}"
# #             password = "${var.user_information.passwd}"
# #         }
# #     }

# # Execute main ansible playbook
#     provisioner "local-exec" {
#         command = "ansible-playbook ../ansible/tasks/main.yaml -i ../ansible/inventory.yaml --vault-password-file ../ansible/nocommit/vaultpass"
#     }
    
#     depends_on = [
#       time_sleep.wait_180_seconds
#     ]
# }