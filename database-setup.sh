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
              sudo systemctl start mongod
              sudo systemctl daemon-reload
              sudo systemctl enable mongod
              mongosh --eval 'use admin; db.createUser({user: "myUser", pwd: "myPassword", roles: [{role: "userAdminAnyDatabase", db: "admin"}]})'
              echo "#!/bin/bash
              mkdir backup
              mongodump --out ./backup
              tar -zcvf backup.tar.gz ./backup
              aws s3 cp backup.tar.gz s3://my-bucket-mrunal
              rm -rf ./backup backup.tar.gz" > /home/ec2-user/backup.sh
              chmod +x /home/ec2-user/backup.sh
              (crontab -l 2>/dev/null; echo "0 0 * * * /home/ec2-user/backup.sh") | crontab -
              sudo yum install -y awslogs
              sudo service awslogs start
              sudo chkconfig awslogs on