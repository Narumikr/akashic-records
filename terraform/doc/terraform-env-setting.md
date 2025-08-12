## Terrafromディレクトリ構成とファイルについて

今回はじめてのTerraformで作成したIaCプロジェクトのディレクトリ構成と作成したTerraformファイルについての備忘録を残す

### ディレクトリ構成

以下ディレクトリ構成で今回は対応した

Moduleディレクトリを作成することでコードの再利用性が高まる

```
terraform/
├── modules/
│   ├── cloudfront/
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── s3/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── main.tf
├── terraform.tfvars
├── outputs.tf
└── variables.tf
```

### 各ファイルについて

#### main.tf

インフラ環境の設計図本体

##### 役割

実際に作るクラウド資源や外部モジュールの宣言、プロバイダ設定を書く中心ファイル

##### 主な内容

- terraform ブロック（required_version / backend 等）
- provider ブロック（例: aws の region など）
- resource（例: S3, CloudFront など）
- module 呼び出し（分割したモジュールを参照）
- data ソース（既存情報の参照）

<details><summary>コード例</summary>

```hcl
terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "s3" {
  source      = "./modules/s3"
  bucket_name = var.bucket_name
}

module "cdn" {
  source                 = "./modules/cloudfront"
  bucket_domain_name     = module.s3.bucket_domain_name
  oac_id                 = module.s3.oac_id
  use_custom_certificate = var.use_custom_certificate
  acm_certificate_arn    = var.acm_certificate_arn
}
```
</details>

#### variables.tf

変数の定義書

##### 役割

main.tfなどから参照する変数を宣言する。

型、デフォルト値、説明、バリデーションを記述する

##### 主な内容

- variable ブロック（type, default, description, validation）
- 入力に必要なものは default を持たせず 必須にしておくと安全

<details><summary>コード例</summary>

```hcl
variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
  default     = "ap-northeast-1"
}

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for static hosting"
}

variable "use_custom_certificate" {
  type        = bool
  description = "Use ACM certificate for CloudFront viewer"
  default     = false
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN (when use_custom_certificate = true)"
  default     = null
  validation {
    condition     = var.acm_certificate_arn == null || can(regex("^arn:aws:acm:", var.acm_certificate_arn))
    error_message = "ACM certificate ARN must start with 'arn:aws:acm:' or be null."
  }
}
```
</details>

#### outputs.tf

実行結果を定義書

##### 役割

terraform apply 後に外部へ見せたい値を定義

##### 主な内容

- output ブロック（value, description, sensitive）
- モジュール間で値を渡す場合にも使う（呼び出し側で module.xxx.yyy と参照）

<details><summary>コード例</summary>

```hcl
output "bucket_name" {
  description = "Created S3 bucket name"
  value       = module.s3.bucket_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = module.cdn.domain_name
}
```
</details>

#### terraform.tfvars

実体の入力値

##### 役割

variables.tfで宣言した変数へ実際の値を割り当てるファイル

##### 主な内容

- key = value 形式でシンプルに記述
- terraform.tfvars はデフォルトで自動読込
- *.auto.tfvars も自動読込（複数可）

<details><summary>コード例</summary>

```hcl
# terraform.tfvars
aws_region            = "ap-northeast-1"
bucket_name           = "my-static-site-12345"
use_custom_certificate = true
acm_certificate_arn   = "arn:aws:acm:ap-northeast-1:123456789012:certificate/xxxx-xxxx"
```
</details><br />

環境ごとにtfvarsファイルを用意して、コマンドで切り替えられる

```bash
terraform apply -var-file=dev.tfvars
terraform apply -var-file=prod.tfvars
```