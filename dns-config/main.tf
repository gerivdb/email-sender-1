# Ultra-Advanced 8-Level Framework - DNS Infrastructure
# Generated: 2025-06-08 21:46:52

terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "domain" {
  description = "Primary domain name"
  type        = string
  default     = "branching-framework.com"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

# Cloudflare DNS Records
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  value   = "203.0.113.10"
  type    = "A"
  ttl     = 300
  proxied = true
}

resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = "203.0.113.10"
  type    = "A"
  ttl     = 300
  proxied = true
}

# Ultra-Advanced Framework Subdomains
resource "cloudflare_record" "api" {
  zone_id = var.cloudflare_zone_id
  name    = "api"
  value   = "203.0.113.77"
  type    = "A"
  ttl     = 300
  proxied = true
} resource "cloudflare_record" "edge" {
  zone_id = var.cloudflare_zone_id
  name    = "edge"
  value   = "203.0.113.73"
  type    = "A"
  ttl     = 300
  proxied = true
} resource "cloudflare_record" "admin" {
  zone_id = var.cloudflare_zone_id
  name    = "admin"
  value   = "203.0.113.53"
  type    = "A"
  ttl     = 300
  proxied = true
} resource "cloudflare_record" "monitoring" {
  zone_id = var.cloudflare_zone_id
  name    = "monitoring"
  value   = "203.0.113.19"
  type    = "A"
  ttl     = 300
  proxied = true
} resource "cloudflare_record" "docs" {
  zone_id = var.cloudflare_zone_id
  name    = "docs"
  value   = "203.0.113.54"
  type    = "A"
  ttl     = 300
  proxied = true
} resource "cloudflare_record" "cdn" {
  zone_id = var.cloudflare_zone_id
  name    = "cdn"
  value   = "203.0.113.81"
  type    = "CNAME"
  ttl     = 300
  proxied = true
}

# Regional Load Balancer
resource "cloudflare_load_balancer_pool" "us_east" {
  name = "us-east-pool"
  
  origins {
    name    = "us-east-1"
    address = "203.0.113.30"
    enabled = true
    weight  = 1
  }
  
  monitor = cloudflare_load_balancer_monitor.ultra_framework.id
}

resource "cloudflare_load_balancer_pool" "eu_west" {
  name = "eu-west-pool"
  
  origins {
    name    = "eu-west-1"
    address = "203.0.113.32"
    enabled = true
    weight  = 1
  }
  
  monitor = cloudflare_load_balancer_monitor.ultra_framework.id
}

resource "cloudflare_load_balancer_pool" "ap_southeast" {
  name = "ap-southeast-pool"
  
  origins {
    name    = "ap-southeast-1"
    address = "203.0.113.34"
    enabled = true
    weight  = 1
  }
  
  monitor = cloudflare_load_balancer_monitor.ultra_framework.id
}

# Global Load Balancer
resource "cloudflare_load_balancer" "global" {
  zone_id          = var.cloudflare_zone_id
  name             = "global-ultra-framework"
  fallback_pool_id = cloudflare_load_balancer_pool.us_east.id
  
  default_pool_ids = [
    cloudflare_load_balancer_pool.us_east.id,
    cloudflare_load_balancer_pool.eu_west.id,
    cloudflare_load_balancer_pool.ap_southeast.id
  ]
  
  description = "Global load balancer for Ultra-Advanced 8-Level Framework"
  
  # Geo-steering
  region_pools {
    region   = "WNAM"
    pool_ids = [cloudflare_load_balancer_pool.us_east.id]
  }
  
  region_pools {
    region   = "WEU"
    pool_ids = [cloudflare_load_balancer_pool.eu_west.id]
  }
  
  region_pools {
    region   = "SEAS"
    pool_ids = [cloudflare_load_balancer_pool.ap_southeast.id]
  }
}

# Health Monitor
resource "cloudflare_load_balancer_monitor" "ultra_framework" {
  expected_body   = "Ultra-Advanced Framework Healthy"
  expected_codes  = "200"
  method          = "GET"
  timeout         = 10
  path            = "/health"
  interval        = 60
  retries         = 2
  description     = "Ultra-Advanced Framework Health Check"
  type            = "http"
  port            = 80
}

# Page Rules for Performance
resource "cloudflare_page_rule" "api_cache" {
  zone_id  = var.cloudflare_zone_id
  target   = "api..domain/*"
  priority = 1
  
  actions {
    cache_level         = "cache_everything"
    edge_cache_ttl      = 300
    browser_cache_ttl   = 300
    security_level      = "high"
    ssl                 = "full"
    always_use_https    = true
  }
}

# WAF Rules
resource "cloudflare_filter" "rate_limit" {
  zone_id     = var.cloudflare_zone_id
  description = "Rate limiting for Ultra-Advanced Framework"
  expression  = "(http.request.uri.path contains \"/api/\" and rate(1m) > 1000)"
}

resource "cloudflare_firewall_rule" "rate_limit" {
  zone_id     = var.cloudflare_zone_id
  description = "Rate limit API requests"
  filter_id   = cloudflare_filter.rate_limit.id
  action      = "challenge"
  priority    = 1
}

# Outputs
output "dns_records" {
  description = "DNS records created"
  value = {
    root_domain = cloudflare_record.root.hostname
    api_domain  = cloudflare_record.api.hostname
    edge_domain = cloudflare_record.edge.hostname
  }
}

output "load_balancer_hostname" {
  description = "Global load balancer hostname"
  value       = cloudflare_load_balancer.global.id
}
