#!/bin/bash
set -x

secGroup="sg-d03019b5"
ami="ami-eceba695"
keyName="DT.STAGEQA.KEY"
keyLocation="/Users/mykola_artemyshyn/.ssh/DTSTAGEQAKEY.pem"
profile="--profile preprd"




instance_id=$(aws ec2 run-instances --image-id $ami --count 1 --instance-type t2.micro \
              --key-name $keyName --security-group-ids $secGroup --tag-specifications \
              'ResourceType=instance,Tags=[{Key=test,Value=test}]' $profile --output text)

echo $instance_id
sleep 30

name=$(aws ec2 describe-instances $instance_id $profile | awk '/INSTANCE/{print $4}')
echo $name

ssh -i $keyLocation  ubuntu@$name -o StrictHostKeyChecking=no
