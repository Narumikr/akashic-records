# CloudFrontのOrigin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for S3 bucket ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always" # 全てのオリジンリクエストがSigV4署名付きになる
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "nextjs_routing" {
  name    = "${var.bucket_name}-nextjs-routing"
  runtime = "cloudfront-js-1.0"
  comment = "Next.js static export routing handler"
  publish = true
  code    = <<-EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // _next/ で始まるパス(Next.jsの静的アセット)はそのまま
    if (uri.startsWith('/_next/')) {
        return request;
    }
    
    // ファイル拡張子があるリクエスト(静的ファイル)はそのまま
    if (uri.includes('.')) {
        return request;
    }
    
    // ルートパスの場合
    if (uri === '/') {
        return request;
    }
    
    // パスが / で終わらない場合(e.g.: /top)
    if (!uri.endsWith('/')) {
        // 対応するディレクトリがある場合は /index.html を追加
        request.uri = uri + '/index.html';
        return request;
    }
    
    // パスが / で終わる場合(e.g.: /top/)
    if (uri.endsWith('/')) {
        request.uri = uri + 'index.html';
        return request;
    }
    
    // その他の場合はルートのindex.htmlにフォールバック
    request.uri = '/index.html';
    return request;
}
EOT
}

# CloudFrontディストリビューション
resource "aws_cloudfront_distribution" "this" {
  origin {
    # S3バケットのドメイン名
    domain_name              = var.s3_bucket_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  # ディストリビューションを有効化
  enabled             = true
  # IPv6を有効化
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "CloudFront distribution for ${var.bucket_name}"
  # 配信エッジロケーションのレベル
  price_class         = var.price_class

  # カスタムエラーページの設定
  # 403エラー(アクセス拒否)
  custom_error_response {
    error_code         = 403
    response_code      = 404
    response_page_path = "/404.html"
  }

  # 404エラー(ページが見つからない)
  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = "/404.html"
  }

  # デフォルトキャッシュビヘイビア
  default_cache_behavior {
    # CloudFrontが許可するHTTPメソッド
    allowed_methods            = ["GET", "HEAD", "OPTIONS"]
    # キャッシュするHTTPメソッド
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "s3-origin"
    # 転送量削減のためのgzip圧縮を自動適用
    compress                   = true
    # HTTPSリダイレクトを強制
    viewer_protocol_policy     = "redirect-to-https"
    # 下記3つはAWS推奨設定
    # キャッシュの最適化
    ## 何をキャッシュするかのルールで、今回の設定は静的コンテンツ向けの設定であり
    ## 不要なヘッダーやCookieを無視してキャッシュ効率を最大化する
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    # S3用のオリジンリクエスト
    ## CloudFront → S3へのリクエストに含める情報
    ## 今回の設定はCORS対応が必要なケース向けのAWS推奨設定
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    # セキュリティヘッダー
    ## CloudFront → ブラウザのレスポンスに追加するHTTPヘッダーの定義
    ## 今回の設定はAWS推奨のセキュリティ強化ヘッダーでStrict-Transport-Security、X-Content-Type-Options、X-Frame-Options などを自動追加
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
    # Next.js用のルーティング関数を適用
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.nextjs_routing.arn
    }
  }

  # _next/ 用の専用キャッシュビヘイビア(Next.jsアセット)
  ordered_cache_behavior {
    path_pattern               = "/_next/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "s3-origin"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    
    # Next.jsアセットは長期キャッシュ
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security_headers.id
  }

  # アクセス国制限の設定
  restrictions {
    geo_restriction {
      # none: 制限なし
      # whitelist: 指定した国のみアクセス許可
      # blacklist: 指定した国からのアクセスを拒否
      restriction_type = var.geo_restriction_type
      # 国コードリスト (e.g.: ["US", "JP"])
      locations        = var.geo_restriction_locations
    }
  }

  # SSL証明書の設定
  viewer_certificate {
    # CloudFrontのデフォルト証明書を使用するか、カスタム証明書を使用するか
    cloudfront_default_certificate = var.use_custom_certificate ? false : true
    # 使用するACM(AWS Certificate Manager)証明書のARNを指定
    ## 独自ドメインでHTTPS配信をするときに必要
    acm_certificate_arn            = var.use_custom_certificate ? var.acm_certificate_arn : null
    # HTTPS接続での証明書提供方式を指定
    ssl_support_method             = var.use_custom_certificate ? "sni-only" : null
    # HTTPS接続で使えるTLSプロトコルの最低バージョンを指定
    minimum_protocol_version       = var.use_custom_certificate ? "TLSv1.2_2021" : null
  }

  # カスタムドメインの設定(オプション)
  aliases = var.use_custom_certificate ? var.domain_aliases : []

  # ログ設定(オプション)
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      # ログにCookie情報を含めるかどうか
      ## 容量の節約や個人情報保護のため残さない
      include_cookies = false
      bucket          = var.logging_bucket
      prefix          = var.logging_prefix
    }
  }

  tags = {
    Name        = "${var.bucket_name}-cloudfront"
    Environment = var.environment
    Purpose     = "Static Website Distribution"
  }

  # Terraformでの依存関係を明示
  depends_on = [
    aws_cloudfront_origin_access_control.this,
    aws_cloudfront_function.nextjs_routing,
    aws_cloudfront_cache_policy.nextjs_caching
  ]
}

# Next.js用カスタムキャッシュポリシー
resource "aws_cloudfront_cache_policy" "nextjs_caching" {
  name        = "${var.bucket_name}-nextjs-caching"
  comment     = "Cache policy for Next.js static export"
  default_ttl = 86400  # 24時間
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# S3バケットポリシーをOAC用に更新
resource "aws_s3_bucket_policy" "cloudfront_oac" {
  bucket = var.bucket_name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowCloudFrontServicePrincipal",
      Effect    = "Allow",
      Principal = {
        # CloudFront以外からのアクセスを拒否
        Service = "cloudfront.amazonaws.com"
      },
      Action   = "s3:GetObject",
      Resource = "${var.s3_bucket_arn}/*",
      Condition = {
        StringEquals = {
          # 特定のCloudFront Distributionからのみアクセスを許可する
          # CloudFront Distributionとはコンテンツを配信するための設定一式のこと
          "AWS:SourceArn" = aws_cloudfront_distribution.this.arn
        }
      }
    }]
  })
}

# AWSが用意しているCloudFrontのマネージドポリシーをTerraform内で参照するための設定
## どの条件でCloudFrontがキャッシュするかを定義するポリシー
data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

## CloudFront → オリジン(S3)に送るリクエスト内容を制御
## "Managed-CORS-S3Origin"はS3静的サイトや静的オブジェクト配信用のCORS対応ポリシー
data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

## CloudFront → ブラウザのレスポンスに追加するHTTPヘッダーの定義
## "Managed-SecurityHeadersPolicy" は AWS推奨のセキュリティ強化セット
data "aws_cloudfront_response_headers_policy" "security_headers" {
  name = "Managed-SecurityHeadersPolicy"
}
