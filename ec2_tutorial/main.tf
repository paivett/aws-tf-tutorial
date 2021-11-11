provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/config"
  profile                 = "sts"
}


resource "aws_instance" "an_ec2_instance" {
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.a_security_group.id]
  associate_public_ip_address = true
  user_data                   = <<-EOT
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
EOT

  tags = {
    Name        = "demo-server"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }

  ami = var.ami_id

  key_name = aws_key_pair.a_key_pair.key_name

  iam_instance_profile = aws_iam_instance_profile.an_instance_profile.name
}

resource "aws_security_group" "a_security_group" {

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }


  tags = {
    Name        = "demo-sg-tutorial"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }
}

resource "aws_key_pair" "a_key_pair" {
  key_name   = "${var.owner}-key-pair"
  public_key = var.public_key
}

resource "aws_iam_role" "an_instance_role" {
  name = "demo-tutorial-instance-role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : {
      "Effect" : "Allow",
      "Principal" : {
        "Service" : ["ec2.amazonaws.com"]
      },
      "Action" : "sts:AssumeRole"
    }
  })

  inline_policy {
    name = "an_inline_policy"

    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Effect" : "Allow",
            "Action" : [
              "iam:Get*",
              "iam:List*",
            ],
            "Resource" : "*"
          }
        ]
      }
    )
  }

  tags = {
    Name        = "demo-instance-role"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }
}

resource "aws_iam_instance_profile" "an_instance_profile" {
  name = "${terraform.workspace}-aws-tutorial"
  role = aws_iam_role.an_instance_role.name
}