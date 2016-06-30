output "key_name" {
  value = "${aws_key_pair.deployer.key_name}"
}

output "depends_id" {
	value = "${aws_key_pair.deployer.id}"
}