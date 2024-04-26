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
  #key_name      = aws_key_pair.deployer.key_name

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
