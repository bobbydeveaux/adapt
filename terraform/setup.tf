# Request the Variables. Can be passed via ENV VARS.
variable "access_key" {}
variable "secret_key" {}
variable "aws_region" {
    default = "eu-west-1"
}

# Specify the provider and access details
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region     = "${var.aws_region}"
}

# Create the key/pair
resource "aws_key_pair" "deployer" {
  key_name   = "demo"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCr9VLgck2nlRF4+VjekojDJA/O6q6qtBrIUM7c2hceF9SiuQQSTgrCKpQhsdV8Lhc4t/lmHyXD4CYeFoI0J+9OrkDlUgJCTXa3QnbYj8Oj4mrnAQ04euwxkhpqRyzYA/SPCxrEJjYz3iO8Mi/+QPJTVlgg5dNxRejngEYnveGN70ieabQZt4uOwwOa93ka8YqNVihr9e52i2QNTi6gDUALwZrc47++RR9Qo3vlbPZZ7yly9UUMZy0FfG9QcQbL2xQzV3JiYyjOfpVf/7lcEpqjdUHOp7CO9vGf6RnyMJz2cQCUcXLo4UA6/6epDXHUnIt/ZwsW/OQzGRYpy9FMl67EsNublVYbM4Ovcv9LMgpx8lXREP1N5a+Qw6SsYQQAlvjQQlvUZY1d/j4zWjh0SzcxRPhI/idk/QxJdiTMQDBXTdW+vhReSQg3P5FTi+h9Yc3qW4euipZK0GfyVu2pJtwxo7PeXaN1kqB/nEnHCqi4Dk3GblzF7/CCbugKbJiRAvd2edvvyHY3rlPKqkVRiPfVqOOvsk+UqrBiMpbwnkcoak6iYfun99N2ID4PfVgJM3WGjTcL9PQOIG98ppAGv4goaTBAUFiNj4gZGI/9ZjDp3/v9tgFgMDTE4vz4OfLrmH1GsrUC5kaOUmGaRu4vQQed8JcbxNaQgjRgqTthdLjtww=="
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  availability_zone       = "eu-west-1a"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
        Name = "Subnet A"
  }
}

# The elastic beanstalk application
resource "aws_elastic_beanstalk_application" "adapt-webapp" {
  name = "Test Application"
  description = "Test Application"
}

# The test environment
resource "aws_elastic_beanstalk_environment" "testenv" {
  name                  = "testenv"
  application           = "${aws_elastic_beanstalk_application.adapt-webapp.name}"
  solution_stack_name   = "64bit Amazon Linux 2016.03 v2.1.0 running Docker 1.9.1"
  tier                  = "WebServer"

  # This is the VPC that the instances will use.
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.default.id}"
  }

  # This is the subnet of the ELB
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.default.id}"
  }

  # This is the subnets for the instances.
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.default.id}"
  }

  # You can set the environment type, single or LoadBalanced
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  # Example of setting environment variables
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_ENVIRONMENT"
    value     = "test"
  }

  # Optional, if you want to add a key pair to your instances
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = "${aws_key_pair.deployer.key_name}"
  }

  # Are the load balancers multizone?
  setting {
    namespace = "aws:elb:loadbalancer"
    name      = "CrossZone"
    value     = "true"
  }

  # Enable connection draining.
  setting {
    namespace = "aws:elb:policies"
    name      = "ConnectionDrainingEnabled"
    value     = "true"
  }
}