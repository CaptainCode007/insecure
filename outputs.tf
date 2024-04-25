output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = [aws_subnet.private1.id, aws_subnet.private2.id]
}


output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.cluster.name
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.instance.id
}

output "ec2_instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.instance.public_ip
}


output "ecr_repository_name" {
  description = "The name of the ECR repository"
  value       = aws_ecr_repository.repository.name
}

variable "private_subnet_cidr_1" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_az" {
  description = "Availability zone for private subnet"
  type        = string
  default     = "us-east-1a"
}


