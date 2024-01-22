******************************************************************************************************* Launching an EC2 Instance Using Bash Script ***************************************************************************************************************************************************
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


******************************************************************************************************* Launching an EC2 Instance UsingTerraform ***************************************************************************************************************************************************

#provider.tf 

provider "aws" {
  region = "us-west-1"
}

#main.tf

resource "aws_key_pair" "bametechkeys" {
  key_name   = "bametechkeys"
  public_key = file("${path.module}/bametechkeys.pub")
}

resource "aws_security_group" "WebAccessDMZ" {
  name        = "WebAccessDMZ"
  description = "Security group for web access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "Test_Instance_1" {
  ami           = "ami-03b11753a40ee7d1f"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.bametechkeys.key_name

  security_groups = [aws_security_group.WebAccessDMZ.name]

  tags = {
    Name = "Test-Instance-1"
  }
}

#output.tf
output "instance_public_ip" {
  value = aws_instance.Test_Instance_1.public_ip
}

************************************************************************************************************************** CloudFormation Template *************************************************************************************************************************

AWSTemplateFormatVersion: '2010-09-09'
Description: Template to create an EC2 instance with a security group.

Parameters:
  KeyName:
    Type: String
    Description: Name of an existing EC2 KeyPair to enable SSH access to the instance

Resources:
  WebAccessDMZSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for web access
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: icmp
          FromPort: -1
          ToPort: -1
          CidrIp: 0.0.0.0/0

  TestInstance1:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-03b11753a40ee7d1f
      InstanceType: t2.micro
      KeyName: !Ref KeyName
      SecurityGroups:
        - !Ref WebAccessDMZSecurityGroup
      Tags:
        - Key: Name
          Value: Test-Instance-1

Outputs:
  InstancePublicIP:
    Description: The Public IP address of the EC2 instance.
    Value: !GetAtt TestInstance1.PublicIp
