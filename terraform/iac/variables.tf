variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.bucket_name)) && length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "Bucket name must be a valid S3 bucket name (3-63 characters, lowercase letters, numbers, and hyphens only)."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "geo_restriction_type" {
  description = "Type of geo restriction for CloudFront"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Geo restriction type must be one of: none, whitelist, blacklist."
  }
}

variable "geo_restriction_locations" {
  description = "List of country codes for geo restriction (ISO 3166-1 alpha-2 codes, e.g., ['US', 'JP', 'GB'])"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for location in var.geo_restriction_locations : can(regex("^[A-Z]{2}$", location))
    ])
    error_message = "All geo restriction locations must be valid 2-letter country codes (ISO 3166-1 alpha-2)."
  }
}

variable "use_custom_certificate" {
  description = "Whether to use a custom SSL certificate"
  type        = bool
  default     = false
}

variable "domain_aliases" {
  description = "List of domain aliases for the CloudFront distribution (e.g., ['example.com', 'www.example.com'])"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for domain in var.domain_aliases : can(regex("^[a-zA-Z0-9][a-zA-Z0-9\\-\\.]*[a-zA-Z0-9]$", domain))
    ])
    error_message = "All domain aliases must be valid domain names."
  }
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for custom domain (required if use_custom_certificate is true)"
  type        = string
  default     = null

  validation {
    condition = var.acm_certificate_arn == null || can(regex("^arn:aws:acm:[a-z0-9\\-]+:[0-9]{12}:certificate/[a-f0-9\\-]+$", var.acm_certificate_arn))
    error_message = "ACM certificate ARN must be a valid ARN format or null."
  }
}

variable "enable_cloudfront_logging" {
  description = "Whether to enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket name for CloudFront access logs (required if enable_cloudfront_logging is true)"
  type        = string
  default     = null

  validation {
    condition = var.logging_bucket == null || can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.logging_bucket))
    error_message = "Logging bucket must be a valid S3 bucket name or null."
  }
}

variable "logging_prefix" {
  description = "Prefix for CloudFront log files in the logging bucket"
  type        = string
  default     = "cloudfront-logs/"

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\-_/]*$", var.logging_prefix))
    error_message = "Logging prefix must contain only alphanumeric characters, hyphens, underscores, and forward slashes."
  }
}