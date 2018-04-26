#!/bin/bash
set -x

#Set REQUIREMENTS for new instance
secGroup="sg-894444ec"
ami="ami-eceba695"
awsProfile=""
tagName=""
instanceType=""
awsvpc="vpc-bb8d33de"
awssub="subnet-44472d21"

# How to use this script
usage() {
    cat<<EOF >&2
    How to use:
    $0 -p awsProfile -t tagName -i instanceType 
    Example:
    -p awsprofile: prod, preprd
    -t tagName: Test.QA, Test.ST, Test.PROD
    -i instance_type: t2.micro, m5.large, c4.xlarge
     $0 -p preprd -t Test.QA -i t2.micro 
EOF
}

#Set arguments
while getopts :p:t:i:: opt
do
    case $opt in
        p) awsProfile="$OPTARG";;
        t) tagName="$OPTARG";;
        i) instanceType="$OPTARG";;
        *) usage;;
    esac
done

# Check for arguments, if no arguments, then show usage and exit
if [ $# = 0 ]; then
    usage
    exit 1
fi
#Create new instance
aws ec2 run-instances --profile $awsProfile --image-id $ami --count 1 --instance-type $instanceType \
                      --key-name $keyName --security-group-ids $secGroup \
                      --placement AvailabilityZone=eu-west-1a \
                      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$tagName}]" \
                      --subnet-id $awssub \
                      --user-data file://bootstrap.sh

sleep 60

#Get instance ID
instanceId=$(aws ec2  describe-instances --profile $awsProfile \
              --filters "Name=tag:Name,Values=$tagName" \
              --query "Reservations[*].Instances[*].InstanceId" \
              --output text)

echo "$instanceId"


#Get instance state
instanceState=$(aws ec2 --profile $awsProfile describe-instances \
               --instance-id $instanceId \
               --filters "Name=instance-state-code,Values=16"  \
               --query "Reservations[].Instances[].State.Name")

sleep 5

#Check instance status
TimeWaited=0
while [ "$instanceState" = "pending" ]; do
    if [ $TimeWaited -ge 10 ]; then
        echo "Instance was not successful created after 30 sec"
        exit 1
    fi
    sleep 5
    TimeWaited=$[$TimeWaited+5]

    instanceState=$(aws ec2 --profile $awsProfile describe-instances \
                   --instance-id $instanceId \
                   --filters "Name=instance-state-code,Values=16"  \
                   --query "Reservations[].Instances[].State.Name")
 
    echo "Waiting for instance to be available $TimeWaited s"
    echo "Status: $instanceState"
done

#Describe instance IP address
instanceIp=$(aws --profile $awsProfile ec2 describe-instances \
	--filters "Name=tag-value,Values=$tagName" \
	"Name=instance-state-name,Values=running" \
	--query 'Reservations[*].Instances[*].PrivateIpAddress[]' \
	--output text)

echo "To check tomcat try: http://$instanceIp:8080"
