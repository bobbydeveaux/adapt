variable "vpc_id" {}

# Create a subnet to launch our instances into
module "adapt_aws_subnet" {
  source = "../core/aws_subnet"
  availability_zones      = "us-west-2a,us-west-2b,us-west-2c"
  cidr_block              = "10.0.X.0/24"
  subnet_name             = "Public"
}