variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The default region for resources"
  type        = string
  default     = "us-central1"  # United Arab Emirates region
}

variable "zone" {
  description = "The default zone for compute resources"
  type        = string
  default     = "us-central1"
}

variable "network_name" {
  description = "The name of the VPC network"
  type        = string
  default     = "poc-vpc"
}

variable "subnet_nodes_cidr" {
  description = "CIDR range for the nodes subnet"
  type        = string
  default     = "10.1.0.0/24"
}

variable "subnet_pods_services_cidr" {
  description = "CIDR range for the pods/services subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "subnet_database_cidr" {
  description = "CIDR range for the database subnet"
  type        = string
  default     = "10.1.2.0/24"
}

variable "subnet_jumphost_cidr" {
  description = "CIDR range for the jumphost subnet"
  type        = string
  default     = "10.1.3.0/24"
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "private-gke-cluster"
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "n1-standard-2"
}

variable "gke_disk_size" {
  description = "Disk size for GKE nodes"
  type        = number
  default     = 100
}

variable "vm_name" {
  description = "Name of the Compute Instance"
  type        = string
  default     = "ubuntu-vm"
}

variable "vm_disk_size" {
  description = "Disk size for Compute Instance"
  type        = number
  default     = 100
}

variable "db_instance_name" {
  description = "Name of the Cloud SQL instance"
  type        = string
  default     = "postgres-instance"
}

variable "db_tier" {
  description = "Database tier for Cloud SQL"
  type        = string
  default     = "db-standard-1"
}

variable "storage_bucket_name" {
  description = "Name of the Cloud Storage bucket"
  type        = string
  default     = "poc-storage-bucket"
}

variable "artifact_registry_name" {
  description = "Name of the Artifact Registry"
  type        = string
  default     = "poc-repo"
}