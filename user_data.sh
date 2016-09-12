#!/bin/bash
sudo yum -y update
sudo yum install -y ruby
cd /home/ec2-user
wget https://aws-codedeploy-eu-central-1.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto