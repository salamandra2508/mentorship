#!/bin/bash
set -x

#Set REQUIREMENTS for new instance
secGroup="sg-894444ec"
ami="ami-eceba695"
keyName="DT.STAGEQA.KEY"
keyLocation="/Users/mykola_artemyshyn/.ssh/DTSTAGEQAKEY.pem"
profile="$1"
tagName="$2"
instance_type="$3"
awsvpc="vpc-bb8d33de"
awssub="subnet-44472d21"


#Create new instance
aws ec2 run-instances --profile $profile --image-id $ami --count 1 --instance-type $instance_type \
                      --key-name $keyName --security-group-ids $secGroup \
                      --placement AvailabilityZone=eu-west-1a \
                      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$tagName}]" \
                      --subnet-id $awssub

sleep 60


#describe instance IP address
instance_ip=$(aws --profile $profile ec2 describe-instances \
	--filters "Name=tag-value,Values=$tagName" \
	"Name=instance-state-name,Values=running" \
	--query 'Reservations[*].Instances[*].PrivateIpAddress[]' \
	--output text)
#copy bootstrap script to new instance
scp -i $keyLocation bootstrap.sh ubuntu@$instance_ip:/home/ubuntu

#connect via ssh to new instance and run bootstrap script
ssh -i $keyLocation -t ubuntu@$instance_ip \
'chmod +x bootstrap.sh | /home/ubuntu/bootstrap.sh'
