resource "aws_elastic_beanstalk_application" "default" {
	name        = "${var.application_name}"
	description = "${var.application_desc}"
}