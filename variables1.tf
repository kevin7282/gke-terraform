
variable "project" {
  description = "sincere-actor-377315"
  type = string
  default = "sincere-actor-377315"
}

variable "cluster_name_suffix" {
  description = "A suffix to append to the default cluster name"
  default     = "mission"
}

variable "region" {
  description = "The region to host the cluster in"
  default     = "us-central1"

}

variable "zones" {
  description = "The region to host the cluster in"
  default     = ["us-central1-a", "us-central1-b", "us-central1-f"]

}

variable "network" {
  description = "The VPC network to host the cluster in"
  default     = "webapp-vpc"
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in"
  default     = "webapp-sub"
}

variable "ip_range_pods" {
  description = "The secondary ip range to use for pods"
  default     = "10.0.1.0/24"
}

variable "ip_range_services" {
  description = "The secondary ip range to use for services"
  default     = "10.0.2.0/24"
}

variable "cluster_ipv4_cidr" {
  description = "The secondary ip range to use for services"
  default     = "10.0.3.0/24"
}

variable "compute_engine_service_account" {
  description = "Service account to associate to the nodes in the cluster"
  default = "../sincere-actor-377315-82a38f6a2dc5.json"
}

variable "service_account" {
  description = "Service account to associate to the nodes in the cluster"
  default = "terraform-cicd-gke"
  #default = "../sincere-actor-377315-82a38f6a2dc5.json"
}