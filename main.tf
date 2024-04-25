provider "aws" {
  region = var.region
}

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

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
   public_key = file(local.public_key_path)
}

resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr_block
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "private1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private1_cidr_block
  availability_zone = var.availability_zone_az1
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private2_cidr_block
  availability_zone = var.availability_zone_az2
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_s3_bucket" "bucket" {
  bucket = "my-bucket-mrunal"
  acl    = "private"

}

resource "aws_instance" "instance" {
  ami           = "ami-0a1179631ec8933d7" 
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.sg.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  subnet_id              = aws_subnet.public.id
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              echo "[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/amazon/2/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc" | sudo tee /etc/yum.repos.d/mongodb-org-7.0.repo
              sudo yum install -y mongodb-org
              sudo yum install -y mongodb-org-7.0.7 mongodb-org-database-7.0.7 mongodb-org-server-7.0.7 mongodb-mongosh-7.0.7 mongodb-org-mongos-7.0.7 mongodb-org-tools-7.0.7
              exclude=mongodb-org,mongodb-org-database,mongodb-org-server,mongodb-mongosh,mongodb-org-mongos,mongodb-org-tools
              sudo systemctl daemon-reload
              sudo systemctl start mongod
              sudo systemctl enable mongod
              PUBLIC_DNS_NAME=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
              echo -e "security:\n  authorization: \"enabled\"\n\nnet:\n  port: 27017\n  bindIp: 0.0.0.0,::,$PUBLIC_DNS_NAME" | sudo tee -a /etc/mongod.conf
              sudo systemctl restart mongod
              mongo --eval 'use admin; db.createUser({user: "myUser", pwd: "myPassword", roles: [{role: "userAdminAnyDatabase", db: "admin"}]})'
              echo "#!/bin/bash
              mkdir backup
              mongodump --out ./backup
              tar -zcvf backup.tar.gz ./backup
              aws s3 cp backup.tar.gz s3://my-bucket-mrunal
              rm -rf ./backup backup.tar.gz" > /home/ec2-user/backup.sh
              chmod +x /home/ec2-user/backup.sh
              (crontab -l 2>/dev/null; echo "* * * * * /home/ec2-user/backup.sh") | crontab -
              sudo yum install -y awslogs
              sudo service awslogs start
              sudo chkconfig awslogs on
              EOF

  tags = {
    Name = "MongoDB Server"
  }
}

resource "aws_iam_role" "cluster" {
  name = "my-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_eks_cluster" "cluster" {
  name     = "my-cluster"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
  }

  version = "1.29"

  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.cluster_vpc,
  ]
}

resource "aws_iam_role" "fargate_pod" {
  name = "my-fargate-pod-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod" {
  role       = aws_iam_role.fargate_pod.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

resource "aws_eks_fargate_profile" "default" {
  cluster_name          = aws_eks_cluster.cluster.name
  fargate_profile_name  = "default"
  pod_execution_role_arn = aws_iam_role.fargate_pod.arn

    subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]

  selector {
    namespace = "default"
  }

  depends_on = [
    aws_eks_cluster.cluster,
    aws_iam_role_policy_attachment.fargate_pod,
  ]
}

resource "aws_ecr_repository" "repository" {
  name = "wiz-image"  
  image_tag_mutability = "IMMUTABLE"
}








