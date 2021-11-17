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

  tags = {
    Name = "Demo public bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "all_blocked" {
  bucket = aws_s3_bucket.a_private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_public_access_block" "all_not_blocked" {
  bucket = aws_s3_bucket.a_public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  restrict_public_buckets = false
  ignore_public_acls      = false
}

resource "aws_s3_bucket_policy" "a_public_policy" {
  bucket = aws_s3_bucket.a_public_bucket.id

  policy = jsonencode({
    "Id" : "Policy1637171740486",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Stmt1637171737101",
        "Action" : [
          "s3:GetObject"
        ],
        "Effect" : "Allow",
        "Resource" : "${aws_s3_bucket.a_public_bucket.arn}/*",
        "Principal" : "*",
        "Condition" : {
          "IpAddress" : {
            "aws:SourceIp" : "${var.my_ip_address}/32"
          }
        }
      }
    ]
  })
}
