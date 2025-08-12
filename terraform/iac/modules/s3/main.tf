# S3バケットの作成
resource "aws_s3_bucket" "this" {
  # バケット名の設定
  bucket = var.bucket_name

  # バケットのタグ設定（KeyとValueの組み合わせを記述する）
  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    Purpose     = "Static Website Hosting"
    # ...and more
  }
}

# S3バケットのバージョニング設定
# バージョニングを有効にすることで、オブジェクトの変更履歴を保持できる
# ※ストレージ料金が増えるので注意
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3バケットの暗号化設定
# バケットのデフォルト暗号化ルールを設定
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# パブリックアクセスブロックの設定
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  # CloudFrontのOAC経由でのみアクセスを許可するため、厳格な設定
  block_public_acls       = true   # パブリックACLをブロック
  block_public_policy     = false  # CloudFront側でポリシー管理するため許可
  ignore_public_acls      = true   # 既存のパブリックACLを無視
  restrict_public_buckets = false  # CloudFront側でポリシー管理するため許可
}

# S3バケットポリシー
# CloudFront側でS3のバケットポリシーを設定するため、S3側には設定をしない
# resource "aws_s3_bucket_policy" "this" {
#   bucket = aws_s3_bucket.this.id
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Sid       = "PublicReadGetObject",
#       Effect    = "Allow",
#       Principal = "*",
#       Action    = ["s3:GetObject"],
#       Resource  = "${aws_s3_bucket.this.arn}/*"
#     }]
#   })

#   # パブリックアクセスブロックの設定を適用するために依存関係を追加
#   # 「Public Access Blockの設定が終わってからバケットポリシーを設定して！」の意
#   depends_on = [aws_s3_bucket_public_access_block.this]
# }

# ウェブサイト設定
resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  # ウェブサイトのエントリポイントの設定
  index_document {
    suffix = "index.html"
  }

  # 404エラー時に表示するページを指定
  error_document {
    key = "404.html"
  }
}
