provider "aws" {
  region                  = var.region
  shared_credentials_file = "~/.aws/config"
  profile                 = "sts"
}

resource "aws_launch_template" "a_launch_template" {
  name_prefix   = "demo-template"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.demo_server_security_group.id]

  key_name = aws_key_pair.a_key_pair.key_name

  user_data = base64encode(<<-EOT
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
EOT
)

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "demo-server"
      owner       = "${var.owner}"
      environment = "aws-tutorial"
    }
  }
}

resource "aws_autoscaling_group" "an_auto_scaling_group" {
  name = "demo-asg"
  vpc_zone_identifier = var.subnets
  desired_capacity    = 2
  max_size            = 4
  min_size            = 1

  target_group_arns = [aws_lb_target_group.a_target_group.arn]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.a_launch_template.id
    version = "$Latest"
  }
}


resource "aws_security_group" "demo_server_security_group" {

  # The egress rules are to allow the instances to install packages
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
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["${var.my_ip_address}/32"]
    security_groups = [aws_security_group.an_alb_security_group.id]
  }


  tags = {
    Name        = "sg-demo-server"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }
}

resource "aws_security_group" "an_alb_security_group" {

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip_address}/32"]
  }

  tags = {
    Name        = "sg-demo-alb"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }
}

resource "aws_key_pair" "a_key_pair" {
  key_name   = "${var.owner}-key-pair"
  public_key = var.public_key
}

resource "aws_lb_target_group" "a_target_group" {
  name     = "demo-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  tags = {
    Name        = "demo-alb-tg"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }
}

resource "aws_lb" "a_load_balancer" {
  name               = "demo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.an_alb_security_group.id]
  subnets            = var.subnets

  enable_deletion_protection = false

  tags = {
    Name        = "demo-alb"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.a_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.a_target_group.arn
  }

  tags = {
    Name        = "demo-alb"
    owner       = "${var.owner}"
    environment = "aws-tutorial"
  }
}
