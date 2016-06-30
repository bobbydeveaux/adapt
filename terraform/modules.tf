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

module "key_pair" {
	source     ="./modules/core/aws_key_pair"
	key_name   = "mykey"
	public_key = "rsa"
	depends_id = "na"
}

module "elastic_beanstalk_application" {
	source           ="./modules/core/aws_elastic_beanstalk_application"
	application_name = "test"
	application_desc = "desc"
	depends_id       = "${module.key_pair.depends_id}"
}

module "elastic_beanstalk_environment" {
	source             = "./modules/core/aws_elastic_beanstalk_environment"
	beanstalk_app_name = "${module.elastic_beanstalk_application.application_name}"
	environment_names  = "test,uat,staging,live"
	depends_id         = "${module.key_pair.depends_id}"
}