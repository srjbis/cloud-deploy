resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "gke-subnet"
  ip_cidr_range = "10.10.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.20.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.30.0.0/16"
  }
}

resource "google_container_cluster" "gke" {
  name     = var.cluster_name
  location = var.zone

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.name

  remove_default_node_pool = true

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
  
  /* master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "192.168.29.112/32"
      display_name = "office"
    }
  } */
}

resource "google_container_node_pool" "nodes" {
  name       = "primary-nodes"
  cluster    = google_container_cluster.gke.name
  location   = var.zone
  initial_node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }
  node_config {
    machine_type = var.instance_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
