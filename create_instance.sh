******************************************************************************************************* Launching an EC2 Instance Using Bash Script ***************************************************************************************************************************************************
#!/bin/bash

# Set AWS region
export AWS_DEFAULT_REGION=us-west-1

# Create a security group
sg_id=$(aws ec2 create-security-group --group-name WebAccessDMZ1 --description "WebAccessDMZ1" --output text --query 'GroupId')

# Add rules to the security group
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol icmp --port -1 --cidr 0.0.0.0/0

# Launch an instance
instance_id=$(aws ec2 run-instances --image-id ami-0abcdef1234567890 --count 1 --instance-type t2.micro --key-name ncaldemokey --security-group-ids $sg_id --output text --query 'Instances[0].InstanceId')

# Tag the instance
aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=Bame-Tech-Web-1

echo "Instance created with ID: $instance_id"



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
