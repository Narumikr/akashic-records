# Terraformとプロバイダーのバージョン指定
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWSプロバイダーの設定
provider "aws" {
  region = var.aws_region
}

# S3モジュール
module "s3" {
  source = "./modules/s3"
  
  bucket_name = var.bucket_name
  environment = var.environment
}

# CloudFrontモジュール
module "cloudfront" { 
  source = "./modules/cloudfront"
  
  # 基本設定
  bucket_name            = var.bucket_name
  s3_bucket_domain_name  = module.s3.bucket_regional_domain_name
  s3_bucket_arn         = module.s3.bucket_arn
  environment           = var.environment
  
  # CloudFront設定
  price_class                = var.cloudfront_price_class
  geo_restriction_type       = var.geo_restriction_type
  geo_restriction_locations  = var.geo_restriction_locations
  
  # SSL証明書設定
  use_custom_certificate = var.use_custom_certificate
  domain_aliases        = var.domain_aliases
  acm_certificate_arn   = var.acm_certificate_arn
  
  # ログ設定
  enable_logging = var.enable_cloudfront_logging
  logging_bucket = var.logging_bucket
  logging_prefix = var.logging_prefix
  
  depends_on = [module.s3]
}