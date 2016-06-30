variable "availability_zones" {
	default = "us-west-2a,us-west-2b,us-west-2c"
}
variable "vpc_id" {}
variable "subnet_name" {
	default = "Subnet"
}

variable cidr_block {
	default = "10.0.X.0/24"
}

# Create a subnet, dynamically
resource "aws_subnet" "default" {
  count                   = "${length(split(",",var.availability_zones))}"
  availability_zone       = "${element(split(",",var.availability_zones), count.index)}"
  vpc_id                  = "${var.vpc_id}"
  cidr_block              = "${replace(var.cidr_block, "X", count.index*4)}"
  map_public_ip_on_launch = true
  tags {
        Name = "${var.subnet_name}-${element(split(",",var.availability_zones), count.index)}"
  }
}