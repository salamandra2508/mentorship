#!/bin/bash
set -x

#Set REQUIREMENTS for new instance
secGroup="sg-894444ec"
ami="ami-eceba695"
keyName="DT.STAGEQA.KEY"
keyLocation=""
awsprofile=""
tagName=""
instance_type=""
awsvpc="vpc-bb8d33de"
awssub="subnet-44472d21"


# How to use this script
usage() {
    cat<<EOF >&2
    How to use:
    $0 -p awsprofile -t tagName -i instance_type -k keyLocation
    Example:
    -p awsprofile: prod, preprd
    -t tagName: Test.QA, Test.ST, Test.PROD
    -i instance_type: t2.micro, m5.large, c4.xlarge
    -k keyLocation: set location of ssh key
     $0 -p preprd -t Test.QA -i t2.micro -k /home/user/.ssh/DTSTAGEQAKEY.pem
EOF
}

#Set arguments
while getopts :p:t:i:k:: opt
do
    case $opt in
        p) awsprofile="$OPTARG";;
        t) tagName="$OPTARG";;
        i) instance_type="$OPTARG";;
        k) keyLocation="$OPTARG";;
        *) usage;;
    esac
done

# Check for arguments, if no arguments, then show usage and exit
if [ $# = 0 ]; then
    usage
    exit 1
fi
#Create new instance
aws ec2 run-instances --profile $awsprofile --image-id $ami --count 1 --instance-type $instance_type \
                      --key-name $keyName --security-group-ids $secGroup \
                      --placement AvailabilityZone=eu-west-1a \
                      --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$tagName}]" \
                      --subnet-id $awssub

sleep 20

#Get instance ID
instance_id=$(aws ec2  describe-instances --profile $awsprofile \
              --filters "Name=tag:Name,Values=$tagName" \
              --query "Reservations[*].Instances[*].InstanceId" \
              --output text)

echo "$instance_id"

instance_state="$(aws --profile preprd ec2 describe-instance-status \
                 --instance-id $instance_id | grep INSTANCESTATE | awk {'print $3'})"
sleep 5

TimeWaited=0
while [ "$instance_state" = "pending" ]; do
    if [ $TimeWaited -ge 10 ]; then
        echo "Instance was not successful created after 30 sec"
        exit 1
    fi
    sleep 5
    TimeWaited=$[$TimeWaited+5]
    instance_state="$(aws --profile preprd ec2 describe-instance-status \
                     --instance-id $instance_id | grep INSTANCESTATE | awk {'print $3'})"
    echo "Waiting for instance to be available $TimeWaited s"
    echo "Status: $instance_id"
done










#describe instance IP address
instance_ip=$(aws --profile $awsprofile ec2 describe-instances \
	--filters "Name=tag-value,Values=$tagName" \
	"Name=instance-state-name,Values=running" \
	--query 'Reservations[*].Instances[*].PrivateIpAddress[]' \
	--output text)
#copy bootstrap script to new instance
scp -i $keyLocation bootstrap.sh ubuntu@$instance_ip:/home/ubuntu

#connect via ssh to new instance and run bootstrap script
ssh -i $keyLocation -t ubuntu@$instance_ip \
'chmod +x bootstrap.sh | /home/ubuntu/bootstrap.sh'
