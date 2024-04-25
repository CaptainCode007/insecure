variable "region" {
  description = "The region where the provider resources will be deployed"
  type        = string
  default     = "us-east-1"
}

locals {
  public_key_path = "${path.module}/mykeypair.pub"
}

variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}
variable "private1_cidr_block" {
  description = "The CIDR block for private subnet 1"
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_az1" {
  description = "The availability zone for the resources"
  type        = string
  default     = "us-east-1a"
}

variable "private2_cidr_block" {
  description = "The CIDR block for private subnet 1"
  type        = string
  default     = "10.0.3.0/24"
}

variable "availability_zone_az2" {
  description = "The availability zone for the resources"
  type        = string
  default     = "us-east-1b"
}


