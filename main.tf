provider "aws"{
    region = var.aws_region
}

variable "aws_region"{
    description = "The AWS region to deploy resources into."
    type = string
    default = "us-east-1"
}

variable "instance_type"{
    description = "The EC2 instance type."
    type = string
    default = "t2.micro"
}

variable "ami_id"{
    description = "The AMI ID for the EC2 instance."
    type = string
    default = "ami-0953476d60561c955" # Make sure this AMI ID is valid for your chosen region!
}

variable "user_name"{
    description = "The name for the IAM user."
    type = string
    default = "terraform-user"
}

variable "bucket_name_prefix" {
    description = "A unique prefix for the S3 bucket name."
    type        = string
    default     = "new-bucket-sekiro" # S3 bucket names must be globally unique
}

variable "queue_name" {
    description = "The name for the SQS queue."
    type        = string
    default     = "terraform-queue"
}

# --- Resource Definitions ---

# 1. AWS IAM User (THIS BLOCK WAS MISSING)
resource "aws_iam_user" "example_user" { # Logical name is 'example_user'
    name = var.user_name
    tags = {
        Environment = "Development"
        ManagedBy   = "Terraform"
    }
}


# 2. AWS Security Group for EC2 (allowing SSH)
resource "aws_security_group" "new_sg"{ # Logical name is 'new_sg'
    name = "allow_ssh" # The actual name in AWS Console will be 'allow_ssh'
    description = "Allow SSH inbound traffic"

    ingress {
        description = "SSH from anywhere"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # WARNING: Allowing SSH from anywhere is not recommended for production
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "example-security-group"
    }
}

# 3. AWS EC2 Instance
resource "aws_instance" "new_instance" { # Logical name is 'new_instance'
    ami           = var.ami_id
    instance_type = var.instance_type
    # CORRECTED: Referencing the correct security group logical name
    vpc_security_group_ids = [aws_security_group.new_sg.id]

    tags = {
        Name = "ExampleTerraformInstance"
        ManagedBy = "Terraform"
    }

    # IMPORTANT: Ensure 'my-key-pair' exists in the specified region
    key_name = "my-key-pair"
}

# 4. AWS S3 Bucket
resource "aws_s3_bucket" "example_bucket" { # Logical name is 'example_bucket'
    # Bucket names must be globally unique and follow DNS naming conventions.
    # Using a prefix and random string helps ensure uniqueness.
    bucket_prefix = var.bucket_name_prefix

    tags = {
        Name = "MyExampleTerraformBucket"
        ManagedBy = "Terraform"
    }
}

# 5. AWS SQS Queue (Example of an event resource - Optional, add back if needed)
/*
resource "aws_sqs_queue" "example_queue" {
  name                      = var.queue_name
  delay_seconds             = 0
  max_message_size          = 262144 # 256 KB
  message_retention_seconds = 345600 # 4 days
  receive_wait_time_seconds = 10

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
*/


# --- Outputs ---

# Output the IAM user name
output "iam_user_name" {
    description = "The name of the created IAM user."
    # CORRECTED: Referencing the correct IAM user logical name
    value       = aws_iam_user.example_user.name
}

# Output the EC2 instance public IP (if applicable and associated)
output "ec2_public_ip" {
    description = "The public IP address of the EC2 instance."
    # CORRECTED: Referencing the correct EC2 instance logical name
    value       = aws_instance.new_instance.public_ip
}

# Output the S3 bucket name
output "s3_bucket_name" {
    description = "The name of the created S3 bucket."
    # CORRECTED: Referencing the correct S3 bucket logical name
    value       = aws_s3_bucket.example_bucket.id
}

# Output the SQS queue URL (if you added the SQS resource back)
/*
output "sqs_queue_url" {
  description = "The URL of the created SQS queue."
  value       = aws_sqs_queue.example_queue.url
}
*/