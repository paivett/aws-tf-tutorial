provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/config"
  profile                 = "sts"

  default_tags {
    tags = {
      owner       = "${var.owner}"
      environment = "aws-tutorial"
    }
  }
}

resource "aws_s3_bucket" "a_private_bucket" {
  bucket = "${var.owner}-demo-bucket-private"
  acl    = "private"

  tags = {
    Name = "Demo private bucket"
  }
}

resource "aws_s3_bucket" "a_public_bucket" {
  bucket = "${var.owner}-demo-bucket-public"
  acl    = "private"

  policy = templatefile("policy.json", { bucket_name = "${var.owner}-demo-bucket-public", ip_address = "${var.my_ip_address}" })

  tags = {
    Name = "Demo public bucket"
  }
}

resource "aws_s3_bucket" "a_website_bucket" {
  bucket = "${var.owner}-demo-bucket-website"
  acl    = "private"

  policy = templatefile("policy.json", { bucket_name = "${var.owner}-demo-bucket-website", ip_address = "${var.my_ip_address}" })

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.an_access_log_bucket.id
    target_prefix = "log/"
  }

  tags = {
    Name = "Demo public bucket"
  }
}

resource "aws_s3_bucket" "an_access_log_bucket" {
  bucket = "${var.owner}-demo-bucket-access-log"
  acl    = "private"

  tags = {
    Name = "Demo access log bucket"
  }
}


resource "aws_s3_bucket_public_access_block" "all_blocked" {
  bucket = aws_s3_bucket.a_private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_public_access_block" "all_not_blocked_public" {
  bucket = aws_s3_bucket.a_public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
  ignore_public_acls      = false
}

resource "aws_s3_bucket_public_access_block" "all_not_blocked_website" {
  bucket = aws_s3_bucket.a_website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
  ignore_public_acls      = false
}

resource "aws_s3_bucket_object" "index_html_object" {
  key          = "index.html"
  bucket       = aws_s3_bucket.a_website_bucket.id
  source       = "index.html"
  content_type = "text/html"
}
