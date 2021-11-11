# AWS tutorial
This repo contains some terraform scripts that follows the Udemy [AWS cloud practitioner tutorial](https://www.udemy.com/course/aws-certified-cloud-practitioner-new/)

## Setup
Create a `.tfvars` file, containing all the variables definitions that are used by the different terraform scripts.

Copy this example and fill in the data

```
owner         = "santiago"
vpc_id        = "vpc-123456789"
subnets       = ["subnet-11111", "subnet-22222"]
region        = "us-east-1"
my_ip_address = "1.2.3.4"
ami_id        = "ami-123"
public_key    = "ssh-ed25519 AAAAC3..."
```