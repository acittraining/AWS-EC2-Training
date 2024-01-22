#!/bin/bash

# Variables
REGION="us-west-1"
AMI_ID="ami-03b11753a40ee7d1f"
INSTANCE_TYPE="t2.micro"
SECURITY_GROUP_NAME="WebAccessDMZ"
INSTANCE_NAME="Test-Instance-1"

# Create security group and capture its ID
SG_ID=$(aws ec2 create-security-group --group-name "$SECURITY_GROUP_NAME" --description "Security group for web access" --region "$REGION" --query 'GroupId' --output text)

# Check if security group was created successfully
if [ -z "$SG_ID" ]; then
    echo "Failed to create security group."
    exit 1
fi

# Add SSH rule to security group
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$REGION"

# Add HTTP rule to security group
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$REGION"

# Add ICMP rule to security group
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol icmp --port -1 --cidr 0.0.0.0/0 --region "$REGION"

# Launch the EC2 instance
INSTANCE_ID=$(aws ec2 run-instances --image-id "$AMI_ID" --count 1 --instance-type "$INSTANCE_TYPE" --security-group-ids "$SG_ID" --region "$REGION" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE_NAME}]" --query 'Instances[0].InstanceId' --output text)

# Check if instance was created successfully
if [ -z "$INSTANCE_ID" ]; then
    echo "Failed to create EC2 instance."
    exit 1
fi

echo "Instance created with ID: $INSTANCE_ID"
