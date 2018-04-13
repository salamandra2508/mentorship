#!/bin/bash
set -x

secGroup="sg-d03019b5"
ami="ami-eceba695"
keyName="DT.STAGEQA.KEY"
keyLocation="/Users/mykola_artemyshyn/.ssh/DTSTAGEQAKEY.pem"
profile=" preprd"




#aws ec2 run-instances --image-id $ami --count 1 --instance-type t2.micro \
#              --key-name $keyName --security-group-ids $secGroup \
#               --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Test.QA}]' --profile $profile )
#              describe-instances  --query "Reservations[].Instances[].InstanceId" --output text

instance_ip=$(aws ec2 describe-instances \
              --filter Name=tag:Name,Values=Test.QA $profile | awk '{print $14}')

#echo $instance_id
#sleep 30

#name=$(aws ec2 describe-instances $instance_id $profile --output text  | awk '/INSTANCE/{print $4}')
#echo $name

ssh -i $keyLocation  ubuntu@$instance_id

sudo su

apt-get update
