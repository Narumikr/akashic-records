aws_region = "ap-northeast-1"

bucket_name = "temp-terraform-narumikr"
environment = "dev"

cloudfront_price_class = "PriceClass_100"
geo_restriction_type      = "whitelist"
geo_restriction_locations = ["JP", "US"]

use_custom_certificate = false
domain_aliases         = []

enable_cloudfront_logging = false