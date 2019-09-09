provider "google" {
  credentials = "${file("account.json")}"
  region      = "europe-west1"
}

module "lab_instance" {
    team_name = "team1"
    password = "${var.password}"
    folder_id = "${var.folder_id}"
    source = "./lab"
}
