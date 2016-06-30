##How to Provision an AWS Elastic Beanstalk Instance Using Packer, Ansible, Docker & Terraform

If, like me, you enjoy using all the latest tech tools, you'll enjoy this one, for sure. These tools aren't just for fun, they make our lives so much easier when it comes to building infrastructure, and releasing code.

*Note, all code used in this article can be found [here](https://github.com/bobbydeveaux/adapt)*

First, let's have a quick summary of each tool in this post.

##### Elastic Beanstalk (EB)

A great service from Amazon Web Services which allows you to easily deploy applications in your preferred solution stack. In our example, we're using the Docker solution stack, along with a load balanced environment and auto-scaling. EB sets this all up for us, along with the relevant security groups - amazing!

##### Packer

Packer is a tool from HashiCorp to build your image. It supports various builders i.e. Docker, Vagrant etc, in addition to many provisioning tools i.e. Puppet, Chef, Ansible, etc. You can then export your built image to an AWS AMI, DockerHub or ECR etc.

##### Ansible

Ansible is a favourite of mine when it comes to provisioning. I've used Puppet & Chef in a number of projects, but for ease of use and simplicity, Ansible always comes crawling back. It's Playbook style makes 'recipes' easy to follow and the configuration options are great.

##### Docker

Hopefully this one won't need much of an intro either. Docker is a 'containerisation' technology which allows segregation of services on a given host. Gone are the days of mammoth web servers that have every service running in one place.

##### Terraform

Terraform is another amazing tool from HashiCorp. Gone are the days of opening up the AWS Console to create instances and VPC's; now you can write your infrastructure as code! Define a VPC, define some subnets, define your internet gateway, along with your EB application and environments and then you're on your way to a truly automated infrastructure. Awesome.

### Part 1: Packer, Ansible & Docker

#### Getting Started

Firstly, why are we doing this? It's important to note that this tutorial is built on the premise that you'd like to create a Foundation image to work from. i.e. you'd like to include an image in your Dockerfile, none of the images our there are quite right. For sure you could provision your entire container using a Dockerfile, but that increases the build time, and therefore release time. If your Dockerfile simply pulls in your readily-provisioned foundation image, all it has to do is rollout your new code and your application is up and running blazingly fast. [For more information on Foundation images, see this article from Google.](https://cloud.google.com/solutions/automated-build-images-with-jenkins-kubernetes)

So, how do we begin? The first step is to setup your intial Packer script:

template.json

	{
	  "_comment": "Template",
	  "builders": [

	  ],
	  "provisioners": [

	  ],
	  "post-processors": [

	  ]
	}

As you can see, it's built up of three main blocks, builders, provisioners & post-processors. As mentioned in the beginning of this article, we're going to use Docker, Ansible & DockerHub.

For the builder, I'm using the base CentOS Docker Image. It may be that you're happy using someone elses foundation image, which has other tools already installed, reducing the amount of provisioning you need to do yourself. I prefer to start with the basics though!


	"builders": [
	    {
	      "type": "docker",
	      "image": "centos:latest",
	      "commit": true
	    }
	  ],


Due to the fact that I'm using a fresh image, we're going to have to provision this with a shell command first, so that we can then provision with Ansible.


	"provisioners": [
	    {
	      "type": "shell",
	      "inline": [
	        "rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm",
	        "yum -y update",
	        "yum -y install ansible",
	        "ansible --version"
	      ]
	    }
	]


You could go ahead and run this right now, and you'll see Packer grab the Centos:latest image, and then install Ansible on the container. Wicked, right?!

	packer build template.json

The next step is to setup our Ansible provisioning which can be done like so:

	"provisioners": [
	    {
	      "type": "shell",
	      "inline": [
	        "rpm -iUvh http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-6.noarch.rpm",
	        "yum -y update",
	        "yum -y install ansible",
	        "ansible --version"
	      ]
	    },{
	      "type": "ansible-local",
	      "playbook_file": "./ansible/playbook.yml",
	      "role_paths": [
	          "./ansible/roles/init",
	          "./ansible/roles/server",
	          "./ansible/roles/mongodb",
	          "./ansible/roles/php7",
	          "./ansible/roles/nginx",
	          "./ansible/roles/supervisord",
	          "./ansible/roles/redis"
	      ],
	      "group_vars": "./ansible/{{ user `stage`}}/group_vars"
	    }


For the purpose of this article, I'm not actually going into great detail as to how to use Ansible. However, the 'group_vars' parameter allows us to run our provisioning with different environemnts. I could pass 'stage' as 'dev' so that Ansible knows to install xdebug, disable Opcache etc. When I'm ready to create an identical box, but with 'prod-like' features. i.e no xdebug please, opcache enabled, error reporting switched off etc, then I can pass 'prod' into the stage parameter.

Passing parameters into Packer is pretty easy:


	packer -var stage=dev template.json


Also, you'll notice that we're provisioning this container with everything my might typically see in a LAMP (or LEMP, rather) stack; Linux, Nginx, MongoDB & PHP. I've also got Redis being installed, along with Supervisord for ensuring the services stay running. In the real world, you'd probably only want each container running one service rather than all of them i.e create a packer script to create your PHP container, another one to create your MongoDB container, another for Nginx, etc. All the scripts are in the source code, so just pick and choose what you'd like.

Don't forget though, using these tools is more about reproducible environments than it is creating the perfect micro-service architecture. Automatically provisioning a machine that runs *all* your services, is much better than a bare-metal machine that's been manually 'provisioned'! Use the tools as you see fit to improve your current situation.

If you've checked out the source code and followed so far, you'll now have a container that's been provisioned - so what do we do with it? My preference is to push it to DockerHub, but you could export it as an AWS AMI, or push it to any other container registry.


	"post-processors": [
	    [
	      {
	        "type": "docker-tag",
	        "repository": "bobbydvo/packer-lemp-{{ user `stage`}}",
	        "tag": "latest"
	      },
	      {
	          "type": "docker-push",
	          "login": true,
	          "login_email":    "{{ user `docker_login_email`}}",
	          "login_username": "{{ user `docker_login_username`}}",
	          "login_password": "{{ user `docker_login_password`}}"
	      }
	    ]
	  ]


The above will first tag your image locally. The second will push your image to DockerHub. This uses 'user' variables which you can place at the top of your template.json

	"_comment": "Template file pulling from centos7",
	  "variables": {
	    "docker_login_email":    "{{ env `DOCKER_LOGIN_EMAIL` }}",
	    "docker_login_username": "{{ env `DOCKER_LOGIN_USERNAME` }}",
	    "docker_login_password": "{{ env `DOCKER_LOGIN_PASSWORD` }}"
	  },


You can now run Packer like so:


	DOCKER_LOGIN_EMAIL=your@email.com \
	DOCKER_LOGIN_USERNAME=yourusername \
	DOCKER_LOGIN_PASSWORD=yourpassword \
	packer -var stage=dev template.json


Alternatively, you may wish to put these environment variables in your bash_profile so you don't have to keep typing them.

Further to this, you'll see I have a build.sh in the repository. This is so that I can create both dev-like and prod-like Foundation images:


	envs=( dev prod )
	for i in "${envs[@]}"
	do
	    PACKER_LOG=1 packer build \
	        -var 'stage='$i \
	        ./packer/template.json
	done


You should now have a brand new Foundation image to work from that you can use in your Dockerfile, awesome, right?!

That brings us to an end of this article, but in Part 2 we'll be exploring how to create our Elastic Beanstalk infrastructure using Terraform. After that, I'll show you how to setup automated deployments into your Elastic Beanstalk environment!


## How to use Terraform to setup and configure Elastic Beanstalk

In the previous article, we talk about creating a foundation image, by using Packer and Ansible to provision and build a Docker image.

The next step is to create some infrastructure, so that we can deploy our app to it -  for that, we're going to use another tool from HashiCorp; Terraform@

Terraform has a simple command which will look for any files with the .tf extension. It will also look for .tf.json extension, but this is a more strict markup. It's a bit more flexible to use the standard extension as it allows for more comments.

First, lets create our variables


	# Request the Variables. Can be passed via ENV VARS.
	variable "access_key" {}
	variable "secret_key" {}
	variable "aws_region" {
	    default = "eu-west-1"
	}


Now call:

	terraform apply

Terraform will prompt you for your AWS access key and secret key. You can do this for any variables you'd like to prompt. If you then want to pass them in at runtime, rather than be prompted, you can do it like so:

	TF_VAR_access_key=XXXXX \
	TF_VAR_secret_key=YYYYY \
	terraform apply

So far, we don't have much, so lets use these variables to create a provider, and some simple VPC & 'Networking stuff':

	# Specify the provider and access details
	provider "aws" {
	    access_key = "${var.access_key}"
	    secret_key = "${var.secret_key}"
	    region     = "${var.aws_region}"
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

	# Create a subnet for the ELB & EC2 intances
	resource "aws_subnet" "default" {
	  vpc_id                  = "${aws_vpc.default.id}"
	  availability_zone       = "eu-west-1a"
	  cidr_block              = "10.0.1.0/24"
	  map_public_ip_on_launch = true

	  tags {
	        Name = "Subnet A"
	  }
	}

If you're familiar with AWS, the above should be fairly simple to understand. We've created a VPC, an Internet Gateway, a Route and a Subnet. Feel free to apply these changes and watch the magic. The real show, and what I find amazing, is the ability to simply tear this down:


	TF_VAR_access_key=XXXXX \
	TF_VAR_secret_key=YYYYY \
	terraform destroy


When it sinks in that your infrastructure can be ripped apart by such a simple command, it will open you up to a whole new world of how to design your application code.

Assuming you've had no issue so far, the next step is to create our Elastic Beanstalk application and environments. In this example, we're just going to fire up a test environment, you could simply copy/paste for more.


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


Most of the above, should again be fairly straight forward - but the comments should help if not. With another dash of the apply command, you'll be up and running with a wonderful Elastic Beanstalk application. Elastic Beanstalk itself, will create the necessary Auto-Scaling groups, Security Groups & Elastic Load Balancers, so you don't need to worry about setting this up in Terraform, although you could configure if you wish.

Truly amazing, right? It's a far cry from the days of placing a custom build with Rackspace and waiting for them to send you all the details, right?

One last thing, should you decide you want to SSH into your instances, you need to specify the key/pair. This goes in as another environment setting:

	# Optional, if you want to add a key pair to your instances
	setting {
		namespace = "aws:autoscaling:launchconfiguration"
		name      = "EC2KeyName"
		value     = "${aws_key_pair.deployer.key_name}"
	}

  You'll need to declare the key_pair as a resource to allow that to work:

	  # Create the key/pair
	resource "aws_key_pair" "deployer" {
	  key_name   = "demo"
	  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCr9VLgck2nlRF4+VjekojDJA/O6q6qtBrIUM7c2hceF9SiuQQSTgrCKpQhsdV8Lhc4t/lmHyXD4CYeFoI0J+9OrkDlUgJCTXa3QnbYj8Oj4mrnAQ04euwxkhpqRyzYA/SPCxrEJjYz3iO8Mi/+QPJTVlgg5dNxRejngEYnveGN70ieabQZt4uOwwOa93ka8YqNVihr9e52i2QNTi6gDUALwZrc47++RR9Qo3vlbPZZ7yly9UUMZy0FfG9QcQbL2xQzV3JiYyjOfpVf/7lcEpqjdUHOp7CO9vGf6RnyMJz2cQCUcXLo4UA6/6epDXHUnIt/ZwsW/OQzGRYpy9FMl67EsNublVYbM4Ovcv9LMgpx8lXREP1N5a+Qw6SsYQQAlvjQQlvUZY1d/j4zWjh0SzcxRPhI/idk/QxJdiTMQDBXTdW+vhReSQg3P5FTi+h9Yc3qW4euipZK0GfyVu2pJtwxo7PeXaN1kqB/nEnHCqi4Dk3GblzF7/CCbugKbJiRAvd2edvvyHY3rlPKqkVRiPfVqOOvsk+UqrBiMpbwnkcoak6iYfun99N2ID4PfVgJM3WGjTcL9PQOIG98ppAGv4goaTBAUFiNj4gZGI/9ZjDp3/v9tgFgMDTE4vz4OfLrmH1GsrUC5kaOUmGaRu4vQQed8JcbxNaQgjRgqTthdLjtww=="
	}


Don't worry, that key is just for this article - it's not in use anywhere.

There you have it, a simple a wonderful way to create automated infrastructure using Terraform & Elastic Beanstalk.

All the code used in this article can be found [here](https://github.com/bobbydeveaux/adapt)

So what about deploying an application to said infrastructure? That blog post is coming soon, but you can see the source code for the application [here](https://github.com/bobbydeveaux/adapt-webapp)


