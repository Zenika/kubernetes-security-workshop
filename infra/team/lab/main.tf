
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

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

  project = "${data.google_project.team-project.project_id}"
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

  service_account {
    email = "${google_service_account.sa.email}"
    scopes = ["userinfo-email", "compute-rw", "storage-rw"]
  }

  project = "${data.google_project.team-project.project_id}"
}