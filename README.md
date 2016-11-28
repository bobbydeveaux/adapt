### Adapt
###### AWS, Docker, Ansible, Packer & Terraform

Tooling using Packer & Ansible to create a foundation images. This is intended to be used 'as and when', so that actual deployments don't have to rebuild the entire server. Docker caching alleviates this to some degree, but having these base-boxes helps reliability and versioning. (see: [https://cloud.google.com/solutions/automated-build-images-with-jenkins-kubernetes#immutable_images](https://cloud.google.com/solutions/automated-build-images-with-jenkins-kubernetes#immutable_images))

The Shippable integration currently hangs, as Packer doesn't support docker-in-docker, which is required when using Shippable (Docker )

#### Usage

To use build your foundation image:

```
./build.sh
```

You can then use this in your Dockerfile in the 'FROM' section.

To build your elastic beanstalk infrastructure within a VPC:

```
cd terraform && terraform apply
```