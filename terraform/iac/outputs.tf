output "s3_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = module.s3.bucket_id
}

output "s3_website_endpoint" {
  description = "S3 website endpoint"
  value       = module.s3.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.cloudfront.cloudfront_distribution_id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.cloudfront.cloudfront_domain_name
}

output "website_url" {
  description = "Website URL via CloudFront"
  value       = "https://${module.cloudfront.cloudfront_domain_name}"
}