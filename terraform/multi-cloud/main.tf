# Terraform Multi-Cloud Infrastructure Configuration
# Ultra-Advanced 8-Level Branching Framework - Global Multi-Cloud Deployment

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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    bucket = "branching-framework-terraform-state"
    key    = "multi-cloud/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}

# Variables
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "branching-framework"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "regions" {
  description = "List of regions for multi-region deployment"
  type = map(object({
    aws_region    = string
    azure_region  = string
    gcp_region    = string
    enabled       = bool
  }))
  default = {
    "us-east" = {
      aws_region   = "us-east-1"
      azure_region = "East US"
      gcp_region   = "us-east1"
      enabled      = true
    }
    "us-west" = {
      aws_region   = "us-west-2"
      azure_region = "West US 2"
      gcp_region   = "us-west1"
      enabled      = true
    }
    "eu-central" = {
      aws_region   = "eu-west-1"
      azure_region = "West Europe"
      gcp_region   = "europe-west1"
      enabled      = true
    }
    "asia-pacific" = {
      aws_region   = "ap-southeast-1"
      azure_region = "Southeast Asia"
      gcp_region   = "asia-southeast1"
      enabled      = true
    }
    "au-east" = {
      aws_region   = "ap-southeast-2"
      azure_region = "Australia East"
      gcp_region   = "australia-southeast1"
      enabled      = true
    }
    "latam-south" = {
      aws_region   = "sa-east-1"
      azure_region = "Brazil South"
      gcp_region   = "southamerica-east1"
      enabled      = true
    }
  }
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for DNS management"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

# Providers
provider "aws" {
  alias  = "us_east"
  region = var.regions["us-east"].aws_region
}

provider "aws" {
  alias  = "us_west"
  region = var.regions["us-west"].aws_region
}

provider "aws" {
  alias  = "eu_central"
  region = var.regions["eu-central"].aws_region
}

provider "aws" {
  alias  = "asia_pacific"
  region = var.regions["asia-pacific"].aws_region
}

provider "aws" {
  alias  = "au_east"
  region = var.regions["au-east"].aws_region
}

provider "aws" {
  alias  = "latam_south"
  region = var.regions["latam-south"].aws_region
}

provider "azurerm" {
  features {}
}

provider "google" {
  project = "branching-framework-gcp"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Data sources
data "aws_availability_zones" "available" {
  for_each = var.regions
  provider = aws.${replace(each.key, "-", "_")}
  state    = "available"
}

# Local values
locals {
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Framework   = "8-level-branching"
  }
  
  enabled_regions = {
    for k, v in var.regions : k => v if v.enabled
  }
}

# AWS Infrastructure
module "aws_infrastructure" {
  source = "./modules/aws"
  
  for_each = local.enabled_regions
  
  providers = {
    aws = aws.${replace(each.key, "-", "_")}
  }
  
  project_name = var.project_name
  environment  = var.environment
  region_name  = each.key
  aws_region   = each.value.aws_region
  
  # VPC Configuration
  vpc_cidr = "10.${index(keys(local.enabled_regions), each.key)}.0.0/16"
  
  # EKS Configuration
  eks_cluster_version = "1.28"
  node_groups = {
    general = {
      instance_types = ["t3.medium", "t3.large"]
      capacity_type  = "ON_DEMAND"
      min_size      = 2
      max_size      = 10
      desired_size  = 3
    }
    compute = {
      instance_types = ["c5.xlarge", "c5.2xlarge"]
      capacity_type  = "SPOT"
      min_size      = 0
      max_size      = 20
      desired_size  = 2
    }
    memory = {
      instance_types = ["r5.large", "r5.xlarge"]
      capacity_type  = "ON_DEMAND"
      min_size      = 0
      max_size      = 10
      desired_size  = 1
    }
  }
  
  # RDS Configuration
  rds_config = {
    engine         = "postgres"
    engine_version = "15.4"
    instance_class = "db.r5.large"
    allocated_storage = 100
    max_allocated_storage = 1000
    multi_az       = true
    backup_retention_period = 7
  }
  
  # ElastiCache Configuration
  elasticache_config = {
    node_type = "cache.r6g.large"
    num_cache_nodes = 3
    engine_version = "7.0"
  }
  
  tags = local.common_tags
}

# Azure Infrastructure
module "azure_infrastructure" {
  source = "./modules/azure"
  
  for_each = local.enabled_regions
  
  project_name = var.project_name
  environment  = var.environment
  region_name  = each.key
  azure_region = each.value.azure_region
  
  # Resource Group
  resource_group_name = "${var.project_name}-${each.key}-${var.environment}"
  
  # AKS Configuration
  aks_config = {
    kubernetes_version = "1.28"
    node_pools = {
      system = {
        vm_size    = "Standard_D2s_v3"
        node_count = 3
        min_count  = 1
        max_count  = 5
      }
      user = {
        vm_size    = "Standard_D4s_v3"
        node_count = 2
        min_count  = 0
        max_count  = 10
      }
    }
  }
  
  # PostgreSQL Configuration
  postgresql_config = {
    version = "15"
    sku_name = "GP_Standard_D2s_v3"
    storage_mb = 102400
    backup_retention_days = 7
    geo_redundant_backup_enabled = true
  }
  
  # Redis Configuration
  redis_config = {
    capacity = 2
    family   = "C"
    sku_name = "Standard"
  }
  
  tags = local.common_tags
}

# Google Cloud Infrastructure
module "gcp_infrastructure" {
  source = "./modules/gcp"
  
  for_each = local.enabled_regions
  
  project_name = var.project_name
  environment  = var.environment
  region_name  = each.key
  gcp_region   = each.value.gcp_region
  
  # GKE Configuration
  gke_config = {
    kubernetes_version = "1.28"
    node_pools = {
      default = {
        machine_type = "e2-standard-2"
        disk_size_gb = 50
        min_node_count = 1
        max_node_count = 5
        initial_node_count = 2
      }
      compute = {
        machine_type = "c2-standard-4"
        disk_size_gb = 50
        min_node_count = 0
        max_node_count = 10
        initial_node_count = 1
      }
    }
  }
  
  # Cloud SQL Configuration
  cloudsql_config = {
    database_version = "POSTGRES_15"
    tier = "db-standard-2"
    disk_size = 100
    backup_enabled = true
    high_availability = true
  }
  
  # Memorystore Configuration
  memorystore_config = {
    memory_size_gb = 4
    redis_version = "REDIS_7_0"
    tier = "STANDARD_HA"
  }
  
  labels = local.common_tags
}

# Cloudflare CDN and DNS
resource "cloudflare_zone_settings_override" "branching_framework" {
  zone_id = var.cloudflare_zone_id
  
  settings {
    ssl = "strict"
    always_use_https = "on"
    min_tls_version = "1.2"
    opportunistic_encryption = "on"
    tls_1_3 = "zrt"
    automatic_https_rewrites = "on"
    security_level = "medium"
    browser_check = "on"
    challenge_ttl = 1800
    development_mode = "off"
    email_obfuscation = "on"
    hotlink_protection = "off"
    ip_geolocation = "on"
    ipv6 = "on"
    websockets = "on"
    pseudo_ipv4 = "off"
    privacy_pass = "on"
    response_buffering = "on"
    rocket_loader = "on"
    server_side_exclude = "on"
    sort_query_string_for_cache = "off"
    true_client_ip_header = "off"
    
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    
    security_header {
      enabled = true
    }
  }
}

# Global Load Balancer Records
resource "cloudflare_record" "global_load_balancer" {
  for_each = local.enabled_regions
  
  zone_id = var.cloudflare_zone_id
  name    = "${each.key}.api"
  type    = "A"
  value   = module.aws_infrastructure[each.key].load_balancer_ip
  ttl     = 60
  proxied = true
  
  comment = "Regional load balancer for ${each.key}"
}

# Main API DNS Record
resource "cloudflare_record" "main_api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  type    = "CNAME"
  value   = "us-east.api.branching-framework.com"
  ttl     = 300
  proxied = true
  
  comment = "Main API endpoint"
}

# Health Check Records
resource "cloudflare_record" "health_checks" {
  for_each = local.enabled_regions
  
  zone_id = var.cloudflare_zone_id
  name    = "${each.key}.health"
  type    = "A"
  value   = module.aws_infrastructure[each.key].health_check_ip
  ttl     = 60
  proxied = false
  
  comment = "Health check endpoint for ${each.key}"
}

# Cloudflare Load Balancer for Intelligent Routing
resource "cloudflare_load_balancer_pool" "regional_pools" {
  for_each = local.enabled_regions
  
  name = "${var.project_name}-${each.key}-pool"
  
  origins {
    name    = "${each.key}-primary"
    address = module.aws_infrastructure[each.key].load_balancer_ip
    enabled = true
    weight  = 1
  }
  
  origins {
    name    = "${each.key}-backup"
    address = module.azure_infrastructure[each.key].load_balancer_ip
    enabled = true
    weight  = 0.5
  }
  
  description = "Regional pool for ${each.key}"
  enabled     = true
  minimum_origins = 1
  
  check_regions = ["WEU", "EEU", "WAS", "EAS"]
  
  monitor = cloudflare_load_balancer_monitor.health_check.id
}

resource "cloudflare_load_balancer_monitor" "health_check" {
  expected_codes = "200"
  method         = "GET"
  timeout        = 5
  path           = "/health"
  interval       = 60
  retries        = 2
  description    = "8-Level Branching Framework Health Check"
  
  header {
    header = "Host"
    values = ["api.branching-framework.com"]
  }
}

resource "cloudflare_load_balancer" "global" {
  zone_id = var.cloudflare_zone_id
  name    = "branching-framework-global-lb"
  
  fallback_pool_id = cloudflare_load_balancer_pool.regional_pools["us-east"].id
  
  default_pool_ids = [
    for pool in cloudflare_load_balancer_pool.regional_pools : pool.id
  ]
  
  description = "Global load balancer for 8-Level Branching Framework"
  ttl         = 30
  proxied     = true
  
  # Geographic routing rules
  dynamic "region_pools" {
    for_each = {
      "WNAM" = [cloudflare_load_balancer_pool.regional_pools["us-west"].id, cloudflare_load_balancer_pool.regional_pools["us-east"].id]
      "ENAM" = [cloudflare_load_balancer_pool.regional_pools["us-east"].id, cloudflare_load_balancer_pool.regional_pools["us-west"].id]
      "WEU"  = [cloudflare_load_balancer_pool.regional_pools["eu-central"].id, cloudflare_load_balancer_pool.regional_pools["us-east"].id]
      "EEU"  = [cloudflare_load_balancer_pool.regional_pools["eu-central"].id, cloudflare_load_balancer_pool.regional_pools["us-east"].id]
      "APAC" = [cloudflare_load_balancer_pool.regional_pools["asia-pacific"].id, cloudflare_load_balancer_pool.regional_pools["au-east"].id]
      "OC"   = [cloudflare_load_balancer_pool.regional_pools["au-east"].id, cloudflare_load_balancer_pool.regional_pools["asia-pacific"].id]
    }
    
    content {
      region   = region_pools.key
      pool_ids = region_pools.value
    }
  }
  
  # Performance-based routing
  steering_policy = "geo"
  
  session_affinity = "cookie"
  session_affinity_ttl = 3600
  
  adaptive_routing {
    failover_across_pools = true
  }
}

# WAF Rules
resource "cloudflare_ruleset" "waf_custom_rules" {
  zone_id = var.cloudflare_zone_id
  name    = "8-Level Branching Framework WAF"
  kind    = "zone"
  phase   = "http_request_firewall_custom"
  
  rules {
    action = "block"
    expression = "(http.request.uri.path contains \"admin\" and not ip.src in {192.168.1.0/24})"
    description = "Block admin access from unauthorized IPs"
    enabled = true
  }
  
  rules {
    action = "challenge"
    expression = "(http.request.method eq \"POST\" and http.request.uri.path contains \"api\" and cf.threat_score gt 30)"
    description = "Challenge suspicious POST requests to API"
    enabled = true
  }
  
  rules {
    action = "log"
    expression = "true"
    description = "Log all requests for analysis"
    enabled = true
  }
}

# Rate Limiting
resource "cloudflare_rate_limit" "api_rate_limit" {
  zone_id = var.cloudflare_zone_id
  
  threshold = 1000
  period    = 60
  
  match {
    request {
      url_pattern = "*.branching-framework.com/api/*"
      schemes     = ["HTTP", "HTTPS"]
      methods     = ["GET", "POST", "PUT", "DELETE"]
    }
  }
  
  action {
    mode    = "simulate"
    timeout = 60
    
    response {
      content_type = "application/json"
      body         = jsonencode({
        error = "Rate limit exceeded"
        retry_after = 60
      })
    }
  }
  
  correlate {
    by = "nat"
  }
  
  disabled = false
  description = "API rate limiting for 8-Level Branching Framework"
}

# Outputs
output "aws_clusters" {
  description = "AWS EKS cluster endpoints"
  value = {
    for k, v in module.aws_infrastructure : k => {
      cluster_endpoint = v.cluster_endpoint
      cluster_name     = v.cluster_name
      load_balancer_ip = v.load_balancer_ip
    }
  }
}

output "azure_clusters" {
  description = "Azure AKS cluster endpoints"
  value = {
    for k, v in module.azure_infrastructure : k => {
      cluster_endpoint = v.cluster_endpoint
      cluster_name     = v.cluster_name
      load_balancer_ip = v.load_balancer_ip
    }
  }
}

output "gcp_clusters" {
  description = "GCP GKE cluster endpoints"
  value = {
    for k, v in module.gcp_infrastructure : k => {
      cluster_endpoint = v.cluster_endpoint
      cluster_name     = v.cluster_name
      load_balancer_ip = v.load_balancer_ip
    }
  }
}

output "cloudflare_config" {
  description = "Cloudflare configuration"
  value = {
    load_balancer_hostname = cloudflare_load_balancer.global.name
    dns_records = {
      for record in cloudflare_record.global_load_balancer : record.name => record.value
    }
  }
}

output "global_endpoints" {
  description = "Global service endpoints"
  value = {
    main_api = "https://api.branching-framework.com"
    regional_apis = {
      for k, v in local.enabled_regions : k => "https://${k}.api.branching-framework.com"
    }
    health_checks = {
      for k, v in local.enabled_regions : k => "https://${k}.health.branching-framework.com"
    }
  }
}
