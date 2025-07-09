#!/bin/bash
sudo yum-config-manager --add-repo https://repo.mongodb.org/yum/amazon/2023/mongodb-org/7.0/x86_64/
sudo rpm --import https://pgp.mongodb.com/server-7.0.asc

sudo yum install -y mongodb-org-7.0.12 mongodb-org-database-7.0.12 mongodb-org-server-7.0.12 mongodb-mongosh mongodb-org-mongos-7.0.12 mongodb-org-tools-7.0.12 mongodb-org-database-tools-extra-7.0.12 && sleep 10
sudo yum install -y cronie

sudo sed -i 's/^  bindIp: .*/  bindIp: 0.0.0.0/' /etc/mongod.conf
systemctl start mongod
systemctl enable crond.service 

echo -e '#!/bin/bash \nmongodump -d go-mongodb -o /home/ec2-user/mongo_backup \naws s3 cp /home/ec2-user/mongo_backup s3://terraform-s3-bucket-alanrdze/ --recursive' > /home/ec2-user/dailyBackupScript.sh
chmod +x /home/ec2-user/dailyBackupScript.sh

echo "0 0 * * * bash /home/ec2-user/dailyBackupScript.sh >/home/ec2-user/ScriptLogs.log 2>&1" | crontab -

echo 'db.getSiblingDB("admin").createUser({user: "eksUser",pwd: "wiz123", roles: [ {role: "readWrite", db: "admin"}]})' > /home/ec2-user/mongoScript.js  && sleep 5

mongosh -f /home/ec2-user/mongoScript.js