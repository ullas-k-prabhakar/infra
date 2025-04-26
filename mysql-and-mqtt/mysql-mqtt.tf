# This code is compatible with Terraform 4.25.0 and versions that are backward compatible to 4.25.0.
# For information about validating this Terraform code, see https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration


resource "google_compute_firewall" "allow-mqtt-tf" {
  name    = "allow-mqtt-tf"
  network = "default" # Make sure this matches the network you're using

  allow {
    protocol = "tcp"
    ports    = ["1883"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]            # Or restrict to specific IP ranges if needed
  target_tags   = ["mqtt-plain-server-tf"] # Must match the VM tag
  priority      = 1000
  description   = "Allow MQTT traffic on TCP port 1883"
}


resource "google_compute_firewall" "allow-mysql-tf" {
  name    = "allow-mysql-tf"
  network = "default" # Make sure this matches the network you're using

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]             # Or restrict to specific IP ranges if needed
  target_tags   = ["mysql-plain-server-tf"] # Must match the VM tag
  priority      = 1000
  description   = "Allow Mysql traffic on TCP port 3306"
}


resource "google_compute_instance" "mysql-mqtt-plain-server" {
  boot_disk {
    auto_delete = true
    device_name = "mysql-mqtt-plain-server"

    initialize_params {
      image = "projects/debian-cloud/global/images/debian-12-bookworm-v20250311"
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src           = "vm_add-tf"
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
  }

  machine_type = var.vm_server_type

  metadata = {
    enable-osconfig = "TRUE"
    startup-script = templatefile("${path.module}/utils/setup-mariadb-mqtt.tpl", {
      mysql_db_name       = var.mysql_db_name
      mysql_user          = var.mysql_user
      mysql_user_password = var.mysql_user_password
      mysql_root_password = var.mysql_root_password
      mqtt_username       = var.mqtt_username
      mqtt_password       = var.mqtt_password
      duck_domain_name    = var.duck_domain_name
      duck_token          = var.duck_token

    })
  }


  name = "mysql-mqtt-plain-server"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/atom-455906/regions/us-central1/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "terraform-admin@atom-455906.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["mqtt-plain-server-tf", "mysql-plain-server-tf"]
  zone = "us-central1-c"
}


resource "random_id" "suffix" {
  byte_length = 2
}
module "ops_agent_policy" {
  source        = "github.com/terraform-google-modules/terraform-google-cloud-operations/modules/ops-agent-policy"
  project       = "atom-455906"
  zone          = "us-central1-c"
  assignment_id = "goog-ops-agent-v2-x86-template-1-4-0-us-central1-c-${random_id.suffix.hex}"
  agents_rule = {
    package_state = "installed"
    version       = "latest"
  }
  instance_filter = {
    all = false
    inclusion_labels = [{
      labels = {
        goog-ops-agent-policy = "v2-x86-template-1-4-0"
      }
    }]
  }
}
