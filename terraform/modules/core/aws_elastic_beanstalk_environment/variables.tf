variable "environment_names" {
	default = "integration,test"
}
variable "beanstalk_app_name" {}
variable "solution_stack_name" {
  default = "64bit Amazon Linux 2016.03 v2.1.0 running Docker 1.9.1"
}
variable "tier" {
  default = "WebServer"
}
variable "depends_id" {}