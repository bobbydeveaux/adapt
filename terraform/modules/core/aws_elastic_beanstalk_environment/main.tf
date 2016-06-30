resource "aws_elastic_beanstalk_environment" "default" {
  count                 = "${length(split(",", var.environment_names))}"
  name                  = "${element(split(",", var.environment_names), count.index)}"
  application           = "${var.beanstalk_app_name}"
  solution_stack_name   = "${var.solution_stack_name}"
  tier                  = "${var.tier}"
}