# h2

h2 is a heroku like PaaS for IQSS at Harvard University.

h2 originates from issue epic `#DevOpsProjects/795` ["Build and release Heroku replacement H2"](https://github.com/hmdc/DevOpsProjects/issues/795)

## Index

* [[1-deploying-h2-nerc-openstack]]

## Directory structure

* `src/disk-image-builder`: this builds and uploads the caprover image to openstack
* `test/caprover` contains Vagrantfile for a 1 host [Caprover](https://caprover.com/)[^caprover] setup on a private network with NAT outbound. 

[^caprover]: Caprover is an open source Platform as a Service (PaaS).