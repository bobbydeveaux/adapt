output "application_name" {
  value = "${aws_elastic_beanstalk_application.default.name}"
}

output "depends_id" {
	value = "${aws_elastic_beanstalk_application.default.id}"
}