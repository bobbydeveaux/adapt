### Adapt
###### AWS, Docker, Ansible, Packer & Terraform

Tooling using Packer & Ansible to create dev-like & prod-like foundation images. These are intended to be used 'as and when', so that actual deployments don't have to rebuild the entire server. Docker caching alleviates this to some degree, but having these base-boxes helps reliability and versioning. (see: [https://cloud.google.com/solutions/automated-build-images-with-jenkins-kubernetes#immutable_images](https://cloud.google.com/solutions/automated-build-images-with-jenkins-kubernetes#immutable_images))

The Shippable integration currently hangs, as Packer doesn't support docker-in-docker, which is required when using Shippable (Docker )

#### Usage

To use build your foundation images:

```
./build.sh
```

It will build a dev-like base, and a prod-like base box. You can then use these in your Dockerfile in the 'FROM' section.

To build your elastic beanstalk infrastructure within a VPC:

```
cd terraform && terraform apply
```