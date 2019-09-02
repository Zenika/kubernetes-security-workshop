
data "google_project" "team-project" {
  project_id = "ksw-${var.team_name}"
}

resource "google_service_account" "sa" {
  account_id   = "team-lab"
  display_name = "SA for the team lab"
  project = "${data.google_project.team-project.project_id}"
}


resource "google_project_iam_binding" "registry-user" {
  project = "${data.google_project.team-project.project_id}"
  role    = "roles/storage.admin"

  members = [
    "serviceAccount:${google_service_account.sa.email}"
  ]
}

data "google_compute_subnetwork" "default-subnet" {
  name   = "default"
  project = "${data.google_project.team-project.project_id}"
}

resource "tls_private_key" "generated_keypair" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

resource "local_file" "private_key" {
  filename = "${path.module}/${var.team_name}-key.pem"
  content  = "${tls_private_key.generated_keypair.private_key_pem}"
}

resource "google_compute_instance" "shell" {
  name         = "shell"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"

  tags = ["${var.team_name}", "shell"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.default-subnet.self_link}"
    network_ip = "10.132.0.20"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "${file("${path.module}/shell-startup.sh")}"
  metadata = {
    sshKeys = "${var.ssh_user}:${tls_private_key.generated_keypair.public_key_openssh}"
  }

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

  project = "${data.google_project.team-project.project_id}"
  provisioner "file" {
    source      = "${path.module}/${var.team_name}-key.pem"
    destination = "/home/ubuntu/.ssh/id_rsa"

    connection {
        host = "${self.network_interface.0.access_config.0.nat_ip}"
        type = "ssh"
        user = "ubuntu"
        private_key = "${tls_private_key.generated_keypair.private_key_pem}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 400 /home/ubuntu/.ssh/id_rsa",
    ]
    connection {
        host = "${self.network_interface.0.access_config.0.nat_ip}"
        type = "ssh"
        user = "ubuntu"
        private_key = "${tls_private_key.generated_keypair.private_key_pem}"
    }
  }

  provisioner "file" {
    source      = "${path.module}/cluster-init.sh"
    destination = "/home/ubuntu/cluster-init.sh"

    connection {
        host = "${self.network_interface.0.access_config.0.nat_ip}"
        type = "ssh"
        user = "ubuntu"
        private_key = "${tls_private_key.generated_keypair.private_key_pem}"
    }
  }  

  provisioner "remote-exec" {
    inline = [
      "sudo cp /home/ubuntu/cluster-init.sh /usr/local/bin",
      "sudo chmod 755 /usr/local/bin/cluster-init.sh",
      "/usr/local/bin/cluster-init.sh",
    ]
    connection {
        host = "${self.network_interface.0.access_config.0.nat_ip}"
        type = "ssh"
        user = "ubuntu"
        private_key = "${tls_private_key.generated_keypair.private_key_pem}"
    }
  }  
}

resource "google_compute_instance" "controller" {
  name         = "controller"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"

  tags = ["${var.team_name}", "controller"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.default-subnet.self_link}"
    network_ip = "10.132.0.21"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "${file("${path.module}/controller-startup.sh")}"
  metadata = {
    sshKeys = "${var.ssh_user}:${tls_private_key.generated_keypair.public_key_openssh}"
  }

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

  project = "${data.google_project.team-project.project_id}"
}

resource "google_compute_instance" "worker" {
  count = 2

  name         = "worker-${count.index}"
  machine_type = "n1-standard-1"
  zone         = "${var.zone}"

  tags = ["${var.team_name}", "worker"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-lts"
    }
  }

  // Local SSD disk
  scratch_disk {
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.default-subnet.self_link}"
    network_ip = "10.132.0.2${count.index + 2}"

    access_config {
      // Ephemeral IP
    }
  }

  metadata_startup_script = "${file("${path.module}/worker-startup.sh")}"
  metadata = {
    sshKeys = "${var.ssh_user}:${tls_private_key.generated_keypair.public_key_openssh}"
  }

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

  project = "${data.google_project.team-project.project_id}"
}
