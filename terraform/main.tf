terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

# AWS Provider Configuration
provider "aws" {
  alias  = "us_east"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_west"
  region = "us-west-2"
}

provider "aws" {
  alias  = "au_east"
  region = "ap-southeast-2"
}

# Azure Provider Configuration
provider "azurerm" {
  features {}
}

# GCP Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = "asia-southeast1"
}

# Cloudflare Provider Configuration
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Variables
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "gcp_project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "edge_domains" {
  description = "Edge domains for each region"
  type        = map(string)
  default = {
    us_east     = "edge-us-east.branching-framework.com"
    us_west     = "edge-us-west.branching-framework.com"
    eu_central  = "edge-eu.branching-framework.com"
    asia_pacific = "edge-apac.branching-framework.com"
    au_east     = "edge-au.branching-framework.com"
    latam_south = "edge-latam.branching-framework.com"
  }
}

# AWS EKS Clusters
module "eks_us_east" {
  source = "./modules/eks"
  providers = {
    aws = aws.us_east
  }
  
  cluster_name = "branching-edge-us-east"
  region       = "us-east-1"
  environment  = var.environment
  
  node_groups = {
    edge_nodes = {
      instance_types = ["c6i.2xlarge"]
      min_size      = 2
      max_size      = 20
      desired_size  = 3
    }
    gpu_nodes = {
      instance_types = ["g4dn.xlarge"]
      min_size      = 1
      max_size      = 5
      desired_size  = 2
    }
  }
}

module "eks_us_west" {
  source = "./modules/eks"
  providers = {
    aws = aws.us_west
  }
  
  cluster_name = "branching-edge-us-west"
  region       = "us-west-2"
  environment  = var.environment
  
  node_groups = {
    edge_nodes = {
      instance_types = ["c6i.2xlarge"]
      min_size      = 2
      max_size      = 15
      desired_size  = 3
    }
    gpu_nodes = {
      instance_types = ["g4dn.xlarge"]
      min_size      = 1
      max_size      = 3
      desired_size  = 1
    }
  }
}

# Azure AKS Cluster
module "aks_eu_central" {
  source = "./modules/aks"
  
  cluster_name        = "branching-edge-eu-central"
  location           = "Central Europe"
  environment        = var.environment
  kubernetes_version = "1.28"
  
  node_pools = {
    edge_pool = {
      vm_size      = "Standard_D8s_v3"
      min_count    = 2
      max_count    = 20
      desired_count = 3
    }
    gpu_pool = {
      vm_size      = "Standard_NC6s_v3"
      min_count    = 1
      max_count    = 5
      desired_count = 2
    }
  }
}

# GCP GKE Clusters
module "gke_asia_pacific" {
  source = "./modules/gke"
  
  cluster_name = "branching-edge-apac"
  region       = "asia-southeast1"
  environment  = var.environment
  
  node_pools = {
    edge_pool = {
      machine_type = "c2-standard-8"
      min_count    = 2
      max_count    = 15
      initial_count = 3
    }
    gpu_pool = {
      machine_type = "n1-standard-4"
      accelerator = {
        type  = "nvidia-tesla-t4"
        count = 1
      }
      min_count    = 1
      max_count    = 3
      initial_count = 1
    }
  }
}

# Cloudflare DNS and CDN Configuration
resource "cloudflare_zone" "main" {
  zone = "branching-framework.com"
}

resource "cloudflare_record" "edge_records" {
  for_each = var.edge_domains
  
  zone_id = cloudflare_zone.main.id
  name    = split(".", each.value)[0]
  value   = module.load_balancers[each.key].external_ip
  type    = "A"
  ttl     = 60
  proxied = true
}

# Global Load Balancer
resource "cloudflare_load_balancer_pool" "edge_pools" {
  for_each = var.edge_domains
  
  name = "edge-pool-\"
  
  origins {
    name    = "origin-\-1"
    address = module.load_balancers[each.key].external_ip
    enabled = true
  }
  
  description = "Edge pool for \"
  enabled     = true
  
  monitor = cloudflare_load_balancer_monitor.edge_monitor.id
}

resource "cloudflare_load_balancer_monitor" "edge_monitor" {
  expected_codes = "200"
  method         = "GET"
  timeout        = 5
  path           = "/health"
  interval       = 60
  retries        = 2
  description    = "Edge health monitor"
}

resource "cloudflare_load_balancer" "global" {
  zone_id = cloudflare_zone.main.id
  name    = "branching-framework.com"
  
  fallback_pool_id = cloudflare_load_balancer_pool.edge_pools["us_east"].id
  
  default_pool_ids = [
    for pool in cloudflare_load_balancer_pool.edge_pools : pool.id
  ]
  
  description = "Global load balancer for Ultra-Advanced 8-Level Framework"
  proxied     = true
  
  geo_config {
    country_code = "US"
    pool_ids     = [cloudflare_load_balancer_pool.edge_pools["us_east"].id]
  }
  
  geo_config {
    country_code = "CA"
    pool_ids     = [cloudflare_load_balancer_pool.edge_pools["us_west"].id]
  }
  
  geo_config {
    continent_code = "EU"
    pool_ids       = [cloudflare_load_balancer_pool.edge_pools["eu_central"].id]
  }
  
  geo_config {
    continent_code = "AS"
    pool_ids       = [cloudflare_load_balancer_pool.edge_pools["asia_pacific"].id]
  }
  
  geo_config {
    country_code = "AU"
    pool_ids     = [cloudflare_load_balancer_pool.edge_pools["au_east"].id]
  }
  
  geo_config {
    continent_code = "SA"
    pool_ids       = [cloudflare_load_balancer_pool.edge_pools["latam_south"].id]
  }
}

# Outputs
output "cluster_endpoints" {
  description = "Kubernetes cluster endpoints"
  value = {
    us_east     = module.eks_us_east.cluster_endpoint
    us_west     = module.eks_us_west.cluster_endpoint
    eu_central  = module.aks_eu_central.cluster_endpoint
    asia_pacific = module.gke_asia_pacific.cluster_endpoint
  }
}

output "edge_domains" {
  description = "Edge domain endpoints"
  value = {
    for k, v in var.edge_domains : k => v
  }
}

output "global_load_balancer" {
  description = "Global load balancer endpoint"
  value = cloudflare_load_balancer.global.name
}
