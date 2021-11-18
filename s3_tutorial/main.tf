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

  replication_configuration {
    role = aws_iam_role.replication_role.arn

    rules {
      id     = "a_replication_rule"
      status = "Enabled"

      filter {
        tags = {}
      }
      destination {
        bucket        = aws_s3_bucket.a_website_replica_bucket.arn
        storage_class = "STANDARD"

        replication_time {
          status  = "Enabled"
          minutes = 15
        }

        metrics {
          status  = "Enabled"
          minutes = 15
        }
      }
    }
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

resource "aws_s3_bucket" "a_website_replica_bucket" {
  bucket = "${var.owner}-demo-bucket-website-replica"
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = {
    Name = "Demo website replica bucket"
  }
}

resource "aws_iam_role" "replication_role" {
  name = "demo-s3-website-replication-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication_policy" {
  name = "demo-s3-website-replication-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.a_website_bucket.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
         "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.a_website_bucket.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.a_website_replica_bucket.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}



resource "aws_s3_bucket_public_access_block" "all_blocked_replica" {
  bucket = aws_s3_bucket.a_website_replica_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_public_access_block" "all_blocked_log_acces" {
  bucket = aws_s3_bucket.an_access_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
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
