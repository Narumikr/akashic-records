# modules/cloudfront内で用いている変数の説明や型を定義するファイル
variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket (e.g., my-bucket.s3.amazonaws.com)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9\\-]*[a-z0-9]\\.s3\\.[a-z0-9\\-]+\\.amazonaws\\.com$", var.s3_bucket_domain_name))
    error_message = "S3 bucket domain name must be a valid S3 domain format."
  }
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket (e.g., arn:aws:s3:::my-bucket)"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:s3:::[a-z0-9][a-z0-9\\-]*[a-z0-9]$", var.s3_bucket_arn))
    error_message = "S3 bucket ARN must be a valid ARN format."
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

variable "price_class" {
  description = <<-EOT
    CloudFront distribution price class:
    - PriceClass_All: Use all edge locations (best performance, highest cost)
    - PriceClass_200: Use edge locations in North America, Europe, Asia, Middle East and Africa
    - PriceClass_100: Use edge locations in North America and Europe only (lowest cost)
  EOT
  type        = string
  default     = "PriceClass_100"

  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "geo_restriction_type" {
  description = "Type of geo restriction (none, whitelist, blacklist)"
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
  description = "Whether to use a custom SSL certificate instead of CloudFront default certificate"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for custom domain (required if use_custom_certificate is true)"
  type        = string
  default     = null
}

variable "domain_aliases" {
  description = "List of domain aliases for the CloudFront distribution (e.g., ['example.com', 'www.example.com'])"
  type        = list(string)
  default     = []
}

variable "enable_logging" {
  description = "Whether to enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "logging_bucket" {
  description = "S3 bucket name for CloudFront access logs (required if enable_logging is true)"
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

variable "additional_tags" {
  description = "Additional tags to apply to CloudFront distribution"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.additional_tags : length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be 128 characters or less, and values must be 256 characters or less."
  }
}

variable "default_root_object" {
  description = "Object that CloudFront returns when the root URL is requested"
  type        = string
  default     = "index.html"

  validation {
    condition     = can(regex("^[a-zA-Z0-9\\._\\-/]+$", var.default_root_object))
    error_message = "Default root object must be a valid file path."
  }
}

variable "comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = null
}