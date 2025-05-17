provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
  default     = "ami-0abcdef1234567890"
}

variable "user_name" {
  description = "The name for the IAM user."
  type        = string
  default     = "insecure-terraform-user"
}

variable "bucket_name_prefix" {
  description = "A unique prefix for the S3 bucket name."
  type        = string
  default     = "public-insecure-bucket"
}


resource "aws_iam_user" "insecure_user" {
  name = var.user_name
  tags = {
    Environment = "InsecureTest"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_user_policy" "insecure_user_policy" {
  name = "insecure-broad-access"
  user = aws_iam_user.insecure_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:*",
          "s3:*",
          "iam:*"
        ],
        Resource = "*"
      },
    ]
  })
}


resource "aws_security_group" "insecure_sg" {
  name        = "ssh_open_to_world"
  description = "Allow SSH inbound traffic from anywhere - VULNERABLE"

  ingress {
    description = "SSH from anywhere - VULNERABLE"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "insecure-security-group"
  }
}

resource "aws_instance" "insecure_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.insecure_sg.id]

  tags = {
    Name = "InsecureTerraformInstance"
    ManagedBy = "Terraform"
  }

  key_name = "my-key-pair"
}

resource "aws_s3_bucket" "public_bucket" {
  bucket_prefix = var.bucket_name_prefix

  acl = "public-read"

  tags = {
    Name = "MyPublicInsecureBucket"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "public_bucket_pab" {
  bucket = aws_s3_bucket.public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


output "insecure_iam_user_name" {
  description = "The name of the created insecure IAM user."
  value       = aws_iam_user.insecure_user.name
}

output "insecure_ec2_public_ip" {
  description = "The public IP address of the insecure EC2 instance."
  value       = aws_instance.insecure_instance.public_ip
}

output "public_s3_bucket_name" {
  description = "The name of the created public S3 bucket."
  value       = aws_s3_bucket.public_bucket.id
}
