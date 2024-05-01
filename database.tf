resource "aws_security_group" "sg" {
  name        = "allow_ssh_db"
  description = "Allow SSH and DB traffic"
  vpc_id      = aws_vpc.main.id 

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_iam_role" "role" {
  name = "ec2_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role_policy" "policy" {
  name = "ec2_policy"
  role = aws_iam_role.role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["ec2:*","s3:PutObject","logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_iam_instance_profile" "profile" {
  name = "ec2_profile"
  role = aws_iam_role.role.name
}


resource "aws_instance" "instance" {
  ami           = "ami-0a1179631ec8933d7" 
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true

  user_data = file("${path.module}/database-setup.sh")

  tags = {
    Name = "MongoDB Server"
  }
}
