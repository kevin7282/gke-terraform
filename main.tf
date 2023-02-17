#Setup Google terraform provider
provider "google" {
  region  = var.region
  project = var.project
}

/*
terraform {
  backend "gcs" {
    bucket  = "bucket-name-for-gke-terraform"
    prefix  = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.36"
    }
  }

  required_version = "1.3.8"
}

#Enable compute API and GKE API
resource "google_project_service" "compute" {
  service = "compute.googleapis.com"
}

resource "google_project_service" "container" {
  service = "container.googleapis.com"
}


resource "google_compute_network" "vpc" {
  name                    = "gke-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
  
  depends_on = [
      google_project_service.compute,
      google_project_service.container
    ]
  
}

#Create the VPC network for the Kubernetes cluster
resource "google_compute_network" "vpc" {
  name                    = "webapp-vpc"
  auto_create_subnetworks = "false"
  routing_mode            = "REGIONAL"
  
}

resource "google_project_iam_member" "logWriter" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke-prod.email}"
  project = var.project
}

resource "google_project_iam_member" "metricWriter" {
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke-prod.email}"
  project = var.project
}

resource "google_project_iam_member" "resourceMetadata-write" {
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.gke-prod.email}"
  project = var.project
}



resource "google_service_account" "gke-prod" {
  account_id   = "terraform-cicd-gke"
  display_name = "terraform-cicd-gke"
}

*/




resource "google_compute_subnetwork" "private_subnet" {
  name                     = "gke-private-subnet"
  region                   = "us-central1"
  network                  = var.network
  private_ip_google_access = true
  ip_cidr_range            = "10.0.5.0/24"
}

#Create NAT Gateway and cloud router
resource "google_compute_router" "router" {
  name         = "gke-vpc-router"
  region       = "us-central1"
  network      = var.network
}

resource "google_compute_address" "address" {
  name         = "gke-nat-static-ip"
  address_type = "EXTERNAL"
  region       = "us-central1"
}

locals {
  private_subnets_names = [google_compute_subnetwork.private_subnet.id]
}

resource "google_compute_router_nat" "mist_nat" {
  name                               = "gke-vpc-nat-gateway"
  router                             = google_compute_router.router.name
  region                             = "us-central1"
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.address.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  dynamic "subnetwork" {
    for_each = local.private_subnets_names
    content {
      name    = subnetwork.value
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    }
  }
}

#Create the GKE control plan for the cluster
resource "google_container_cluster" "primary" {
  name                      = "gke-cluster1"
  location                  = "us-central1"
  remove_default_node_pool  = true
  initial_node_count        = 1
  network                   = var.network
  subnetwork                = var.subnetwork
  networking_mode           = "VPC_NATIVE"
  min_master_version        = "1.24.9"
  enable_l4_ilb_subsetting  = true

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.10.0.0/16"
    services_ipv4_cidr_block = "172.18.0.0/16"
  }
  
  master_authorized_networks_config {
     cidr_blocks {
       cidr_block = "0.0.0.0/0"
       display_name = "allowed_cidrs"
     }
  }
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.19.0.0/28"
  }

    /*
  addons_config {
    http_load_balancing {
      disabled = false
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
    gcp_filestore_csi_driver_config {
      enabled = true
    }
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
    managed_prometheus {
      enabled = true
    }
  }
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
  }
  binary_authorization {
      evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }
  */

}

#Create GKE Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "gke-cluster-primary-nodepool"
  location   = "us-central1"
  cluster    = google_container_cluster.primary.name

  autoscaling {
    min_node_count  = 0
    max_node_count  = 2
    location_policy = "BALANCED"
  }
  
   management {
    auto_repair  = true
    auto_upgrade = true
  }


  node_config {
    #service_account = google_service_account.gke-prod.email
    #service_account = var.service_account
    
    labels = {
      node = "primary"
    }
    machine_type = "e2-medium"
    disk_size_gb = 10
    disk_type = "pd-standard"
    tags         = ["gke-node","private-node","primary-node"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

}