#!/bin/bash
set -x

secGroup="sg-894444ec"
ami="ami-eceba695"
keyName="DT.STAGEQA.KEY"
keyLocation="/Users/mykola_artemyshyn/.ssh/DTSTAGEQAKEY.pem"
profile="preprd"
tagName="Test.QA"
awsvpc="vpc-bb8d33de"
awssub="subnet-44472d21"
region=""

#aws ec2 run-instances --profile $profile --image-id $ami --count 1 --instance-type t2.micro \
#                      --key-name $keyName --security-group-ids $secGroup \
#                      --placement AvailabilityZone=eu-west-1a \
#                      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$tagName}]" \
#                      --subnet-id $awssub

#sleep 30



instance_ip=$(aws --profile $profile ec2 describe-instances \
	--filters "Name=tag-value,Values=$tagName" \
	"Name=instance-state-name,Values=running" \
	--query 'Reservations[*].Instances[*].PrivateIpAddress[]' \
	--output text)

ssh -i $keyLocation -t ubuntu@$instance_ip \
'sudo apt-get install -y apache2 default-jdk'
