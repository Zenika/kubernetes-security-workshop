
provider "google" {
  credentials = "${file("account.json")}"
  region      = "europe-west1"
}

data "google_project" "team-project" {
  project_id = "ksw-${var.team_name}"
}

resource "google_service_account" "sa" {
  account_id   = "team-lab"
  display_name = "SA for the team lab"
  project = "${data.google_project.team-project.project_id}"
}

resource "google_project_iam_custom_role" "instance-restarter" {
  role_id     = "instanceRestarter"
  title       = "Instance restarter"
  project     = "${data.google_project.team-project.project_id}"
  description = "A role allowing to restart GCE instances"
  permissions = ["compute.instances.get", "compute.instances.start", "compute.instances.stop", "compute.instances.reset"]
}

resource "google_project_iam_binding" "restart-instance" {
  project = "${data.google_project.team-project.project_id}"
  role    = "projects/${data.google_project.team-project.project_id}/roles/${google_project_iam_custom_role.instance-restarter.role_id}"

  members = [
    "serviceAccount:${google_service_account.sa.email}"
  ]
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
      size  = "30"
      image = "${var.image_project}/shell"
    }
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.default-subnet.self_link}"
    network_ip = "10.132.0.20"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${tls_private_key.generated_keypair.public_key_openssh}"
  }

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

  project = "${data.google_project.team-project.project_id}"
  provisioner "remote-exec" {
    inline = [
      "echo ubuntu:${var.password} | sudo chpasswd"
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
  machine_type = "n1-standard-2"
  zone         = "${var.zone}"

  tags = ["${var.team_name}", "controller"]

  boot_disk {
    initialize_params {
      size  = "30"
      image = "${var.image_project}/controller"
    }
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.default-subnet.self_link}"
    network_ip = "10.132.0.21"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${tls_private_key.generated_keypair.public_key_openssh}"
  }

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-ro", "storage-rw"]
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
      size  = "30"
      image = "${var.image_project}/worker-${count.index}"
    }
  }

  network_interface {
    subnetwork = "${data.google_compute_subnetwork.default-subnet.self_link}"
    network_ip = "10.132.0.2${count.index + 2}"

    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    sshKeys = "${var.ssh_user}:${tls_private_key.generated_keypair.public_key_openssh}"
  }

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-ro", "storage-rw"]
  }

  project = "${data.google_project.team-project.project_id}"
}
