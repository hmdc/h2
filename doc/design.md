# H2 proposed design

## Origination

[hmdc/DevOpsProjects#801](https://github.com/hmdc/DevOpsProjects/issues/801)

## Synopsis

* IQSS provides qualified Harvard-affiliated customers access to a [Heroku](https://www.heroku.com) enterprise account subscription by request.

* Heroku is a platform as a service (PaaS).

* A PaaS allows developers to quickly self-publish web applications/sites by subtracting from developer or institutional consideration everything unrelated to development: Heroku manages all physical and virtual servers, security patching, updates, monitoring, and operational checks. However, it is closed source and cost-prohibitive.
  
* [Caprover](https://github.com/caprover/caprover) is a open source PaaS developed and financially supported by an active community.
  * Apache 2.0 license
  * 9,400 stars on GitHub
  * Uses "Docker swarm" (simpler alternative to Kubernetes) to manage app deployment across multiple servers
  * Single user
  * Frontend and Caprover api server written in TypeScript

* I will replace the functionality of Heroku enterprise by building a Caprover virtual environment for each project currently hosted on Heroku: **H2** for short. 
  
* I intend to host all virtual environments on [NERC's OpenStack platform](https://nerc.mghpcc.org/).

* IQSS will be able to maintain the same level of access and usage control over customer projects or assigned resources provided by Heroku in the new Caprover environments because:
  * NERC is fully integrated into Harvard Key which will permit a seamless login (authentication) experience for Heroku users.
  * In addition, NERC hosts a *ColdFront* installation which manages usage and access to OpenStack resources on the basis of a project group sponsored by a principal investigator or equivalent role (PIE).
  * As all Heroku projects require sponsorship by PIE as well, I can map all Grouper access controls to ColdFront access controls to ensure continuity of authorization: Users in a project group on Heroku will be able to perform equivalent actions on their Caprover project limited by their access scope within the project.

## Product operations

### Customer intake

* Any PIE can request an H2 project space: An H2 project space is a "Project" in OpenStack (read: VPC) on which H2 will be deployed via Terraform.

* PIE should complete an intake form which compensates for all Harvard security and research data controls and resource requirements. Applications which are visible to the public internet and/or applications which manipulate sensitive data should be given extra scrutiny.[^todo-ingestion-form] [^todo-ingestion-security-review]

* Each project migrated from Heroku to H2 will appear as a project in ColdFront. [^todo-create-coldfront-resources-for-pie]
  * Coldfront permits limiting access to consumable resources like cpu and memory in OpenStack.
* Each PIE will be assigned an OpenStack resource allocation on Coldfront.
* Each PIE will be assigned a wildcard domain: `*.project_name.h2.hmdc.harvard.edu` such that any subdomain of `project_name.h2.hmdc.harvard.edu` will CNAME to PIE's H2 installation [^detail-wildcard-domain]
* A wildcard SSL certificate for `*.project_name.h2.hmdc.harvard.edu` will be generated.
* Terraform will provision a Caprover environment on OpenStack within the PIE's OpenStack environment and
configure it to use the wildcard certificate `*.project_name.h2.hmdc.harvard.edu`.
* Terraform will set the appropriate CNAME from `*.project_name.h2.hmdc.harvard.edu` to Caprover instances[^detail-terraform-set-cname-to-lb-or-instance-group]
* An e-mail and/or notification will be sent to PIE, organization that H2 cluster is provisioned.[^todo-onboarding-welcome]

### Add-on applications maintenace

* As in Heroku, customers can deploy add-ons like databases. While I want to allow users to choose any database they would like, I want us to only officially support the following: PostgreSQL and MongoDB. [^todo-determine-addon-requirements]
  
* These add-ons should be treated as critical components and backed up when necessary. [^todo-determine-backup-policy-addons]
  
### Maintaing a relationship with NERC

* Conforming to all NERC regulations
* Maintain awareness about NERC maintenance schedules and downtime. [^todo-relationship-to-nerc]
  
### Maintenance, security

* Each customers' cluster is subject to ongoing security measures which operate on routine or continuous basis.

  * Patching

    * Before patching, a workflow should take a backup of the Caprover cluster through Caprover's backup mechanisms
    * All host operating systems in every cluster should be updated via `yum -y upgrade` at the host-os level.  [^todo-workflow-update-cluster]

  * Scanning

    * All docker containers deployed to Caprover cluster, including Caprover itself, should be routinely inspected for vulnerabilities via an automated process.
    * Vulnerability scanners should also scan open ports/services on the Caprover cluster.
    * Results should be delivered to customer. Automated resolutuon can be considered, but, in most cases I expect that customer's software stacks are fragile. Resolution of maintenance issues that require downtime require an unitial stake in the ground. [^todo-scanning] [^todo-customer-security-remediation-policy]
  
  * Updating images

    * Base images should be updated on a routine basis with the latest patches as part of the development and release pipeline. [^todo-workflow-update-image]

## Development and release pipelines

### Running H2 in development *WIP*

* As of 10/24/2022, the H2 dev environment consists of 1 caprover node. [^todo-create-h2-development-cluster]
* Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/docs/provisioning/docker)
* Follow instructions in the repository: <https://github.com/hmdc/h2/tree/main/test/caprover>

### Pipeline A: Routine patching and updates

* On an automatic and routine basis, Packer will build Vagrant and OpenStack images of our Caprover `servers` and `agents`, which will incorporate the latest patches and security updates to Caprover and the base operating system.
  * A Caprover server and agent image is the same except for a boolean which determines whether the function of the Caprover server is to co-ordinate the activities of the entire cluster or run applications.
  * For small installations, instances can assume both roles.
* Once the Vagrant image has been created, it will be tested with a sample application in a sample VirtualBox cluster to determine whether updating the base image in production will have any negative affects.
* If successful, Vagrant will update the image in NERC, such that any new deployments will use new virtual machine images.
* Should we assume that every customers environment should also be rebuilt upon image update? It would be ideal, but perhaps difficult to accomplish without customer involvement in the process. [^todo-should-images-update-clusters] 

### Pipeline B: Development and testing new features

* H2 is a fork of Caprover. When checking out H2 to develop on patches which will either be mainlined or kept separate, it should be easy to work on Caprover `live` within a development cluster such that development remains a low-latency endeavor. [^todo-build-developer-environment]

* The CURRENT branch of the H2 repository will be `canary`, the STABLE branch will be `stable`.  [^todo-build-developer-workflow]

* All development branches are serialized and merged into Canary via review whereas QA reviews the transition from `canary` to `stable.` [^todo-qa-process]

* Releases will be built from `canary` and `stable` based on timestamp versioning and will contain virtual machine images, docker containers, and npm package as artifacts. [^todo-which-artifacts-should-be-included]

## Migration and plan

### Synopsis

* I want to move every application from Heroku to Caprover in OpenStack.

* Each application and add-ons can be migrated (duplicated) programmatically. [^todo-heroku-to-caprover-app-transition-pipeline]

* All applications migrated should also have their PIEs perform any required documentation if they wish to continue service. [^todo-migrate-customers-from-heroku]

### Y22 Q4

#### Duplicate `evalue.hmdc.harvard.edu`

* evalue.hmdc.harvard.edu resides on Heroku and is a simple application developed by a researcher who no longer works at Harvard. We are maintaining an ancient version of this website by request as it is still heavily used by the researcher's community. 
  
* My stake: Migrating this application onto an H2 cluster by EOY Y22 (with shortcuts) to determine overall techncal feasibility.

### Y23 Q1

Build a workflow which can execute the following function:

1. Given a project name, create wildcard SSL certificates for projects, create appropriate CNAME, and deploy a Caprover/H2 cluster: [^todo-create-coldfront-resources-for-pie]

[^todo-ingestion-form]: 

[^todo-ingestion-security-review]: 

[^todo-create-coldfront-resources-for-pie]: 

[^detail-wildcard-domain]: 

[^detail-terraform-set-cname-to-lb-or-instance-group]: 

[^todo-onboarding-welcome]: 

[^todo-determine-backup-policy-addons]: 

[^todo-migrate-customers-from-heroku]: 

[^todo-create-h2-development-cluster]: 