provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_network" "vpc" {
  name                    = "poc-vpc"
}

resource "google_compute_subnetwork" "nodes" {
  name          = "nodes-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.1.0.0/24"
  region        = var.region
}

resource "google_compute_subnetwork" "pods_services" {
  name          = "pods-services-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.1.1.0/24"
  region        = var.region
}

resource "google_compute_subnetwork" "database" {
  name          = "database-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.1.2.0/24"
  region        = var.region
}

resource "google_compute_subnetwork" "jumphost" {
  name          = "jumphost-subnet"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.1.3.0/24"
  region        = var.region
}

resource "google_compute_instance" "vm" {
  name         = "ubuntu-vm"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
      size  = 100
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.jumphost.id
    access_config {}
  }
}

#resource "google_sql_database_instance" "postgres" {
#  name             = "postgres-instance"
#  database_version = "POSTGRES_13"
#  region           = var.region

#  settings {
#    tier = "db-n1-highmem-2"
#    disk_size = 100
#    disk_type = "PD_SSD"
#    backup_configuration {
#      enabled = true
#    }
#  }
#}


############## test DB################

resource "google_sql_database_instance" "postgres_instance" {
  name             = "my-postgres-instance"            # Cloud SQL instance name
  database_version = "POSTGRES_15"                     # PostgreSQL version (e.g. 15)
  region           = var.region
  #edition          = "ENTERPRISE"                      # Cloud SQL iiiedition (Standard/Enterprise/Enterprise_PLUS)

  deletion_protection = true                           # Prevent accidental deletion (Terraform defaults this to true)

  settings {
    tier              = "db-custom-2-8192"             # 2 vCPU, 8 GB RAM machine type [oai_citation_attribution:6‡stackoverflow.com](https://stackoverflow.com/questions/73002346/how-to-get-internal-ip-of-postgresql-db-in-gcp-created-by-terraform#:~:text=settings%20%7B%20availability_type%20%3D%20,)
    availability_type = "REGIONAL"                     # High availability (multi-zone deployment)

    disk_type       = "PD_SSD"                         # SSD storage for better performance
    disk_size       = 20                               # 20 GB initial disk
    disk_autoresize = true                             # Enable automatic storage growth [oai_citation_attribution:7‡trendmicro.com](https://trendmicro.com/cloudoneconformity/knowledge-base/gcp/CloudSQL/enable-automatic-storage-increase.html#:~:text=Enable%20Automatic%20Storage%20Increase%20,disrupting%20the%20usual%20database%20operations)

    backup_configuration {
      enabled                        = true            # Enable automated backups (daily) [oai_citation_attribution:8‡shisho.dev](https://shisho.dev/dojo/providers/google/Cloud_SQL/google-sql-database-instance/#:~:text=,losses)
      point_in_time_recovery_enabled = true            # Enable Point-in-Time Recovery (continuous WAL backups)

      # Optional settings for backups:
      # start_time = "02:00"                           # (optional) Preferred backup start time (UTC in HH:MM)
      # backup_retention_settings {                   # (optional) Retain a number of backups
      #   retention_unit   = "COUNT"
      #   retained_backups = 7                        # keep last 7 backups (one week)
       }
    }
   }

#########################################

resource "google_storage_bucket" "bucket" {
  name          = "poc-storage-bucket-uni"
  location      = var.region
  storage_class = "STANDARD"
}

resource "google_compute_network" "net" {
  name = "my-network"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-subnetwork"
  network       = google_compute_network.net.id
  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"
}

resource "google_compute_router" "router" {
  name    = "my-router"
  region  = google_compute_subnetwork.subnet.region
  network = google_compute_network.net.id

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name                               = "my-router-nat"
  router                             = google_compute_router.router.name
  region                             = google_compute_router.router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_certificate_manager_certificate" "ssl_cert" {
  name        = "poc-cert"
  description = "SSL Certificate for Load Balancer"

  managed {
    domains = ["example.com"]
  }
}

resource "google_compute_vpn_gateway" "vpn" {
  name    = "vpn-gateway"
  region  = var.region
  network = google_compute_network.vpc.id
}

resource "google_compute_global_address" "lb_ip" {
  name = "lb-ip"
}

resource "google_compute_target_pool" "lb_pool" {
  name = "lb-pool"
}

#resource "google_compute_forwarding_rule" "lb" {
#  name       = "lb-rule"
#  target     = google_compute_target_pool.lb_pool.id
#  ip_address = google_compute_global_address.lb_ip.address
#  region     = var.region  # Ensure the region is the same as the target pool
#}


resource "google_artifact_registry_repository" "artifact_registry" {
  location      = var.region
  repository_id = "poc-repo"
  format        = "DOCKER"
}

resource "google_container_cluster" "gke" {
  name     = "private-gke-cluster"
  location = var.region

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.nodes.id

  initial_node_count = 1  # Set initial node count

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  node_config {
    machine_type = "n1-standard-2"
    disk_size_gb = 100
  }
}

resource "google_monitoring_alert_policy" "critical_alerts" {
  display_name = "Critical Alert"
  combiner     = "OR"

  conditions {
    display_name = "High CPU Usage"
    condition_threshold {
        filter = <<EOF
  metric.type="compute.googleapis.com/instance/cpu/utilization" AND resource.type="gce_instance"
  EOF
        comparison      = "COMPARISON_GT"
        threshold_value = 0.9
        duration        = "60s"
      }
    }
}