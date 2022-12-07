# H2 proposed design

## Origination

[hmdc/DevOpsProjects#801](https://github.com/hmdc/DevOpsProjects/issues/801)

## Synopsis

* IQSS provides qualified Harvard-affiliated customers access to a [Heroku](https://www.heroku.com) enterprise account subscription by request.

* Heroku is a platform as a service (PaaS).

* Active demo: <https://captain.server.demo.caprover.com/#/apps/details/demo-nodejs>

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
  * HMDC Ops will have access to these resources for purposes of deployment, maintenance, and troubleshooting. [^todo-ops-access]
* Each PIE will be assigned a wildcard domain: `*.project_name.h2.hmdc.harvard.edu` such that any subdomain of `project_name.h2.hmdc.harvard.edu` will CNAME to PIE's H2 installation [^detail-wildcard-domain]
* A wildcard SSL certificate for `*.project_name.h2.hmdc.harvard.edu` will be generated.
* Terraform will be used for infrastructure deployment. This might be done manually by HMDC Ops, but ideally would be automated in some system TBD. [^todo-terraform-automation]
* Terraform state will reside on GitLab or OpenStack storage [^todo-terraform-state-management]
* Terraform will onboard PIE onto OpenStack with minimal to no permissions to access/mutate infrastructure in project but maximal permissions inside docker swarm caprover. [^todo-create-minimal-user-access]
* Terraform will provision an immutable Caprover environment on OpenStack within the PIE's OpenStack environment,
configure it to use the wildcard certificate `*.project_name.h2.hmdc.harvard.edu`.
* Terraform will set the appropriate CNAME from `*.project_name.h2.hmdc.harvard.edu` to Caprover instances[^detail-terraform-set-cname-to-lb-or-instance-group]
* Terraform will provision the appropriate service accounts which will provide HMDC with administrative access over customer clusters.[^todo-create-service-accounts] [^todo-scaling-1to1-proj-openstack]
* Terraform will onboard PIE onto OpenStack with minimal permissions to access, mutate infrastructure but maximal permissions inside docker swarm caprover. [^todo-create-minimal-user-access]
* An e-mail and/or notification will be sent to PIE, organization that H2 cluster is provisioned.[^todo-onboarding-welcome]

### Add-on applications maintenace

* As in Heroku, customers can deploy add-ons like databases. While I want to allow users to choose any database they would like, I want us to only officially support the following: PostgreSQL and MongoDB. [^todo-determine-addon-requirements]
  
* These add-ons should be treated as critical components and backed up when necessary.[^todo-determine-backup-policy-addons]
  
### Maintaing a relationship with NERC

* Conforming to all NERC regulations
* Meet regularly
* Maintain awareness about NERC maintenance schedules and downtime. [^todo-relationship-to-nerc]
  
### Maintenance, security

* Each customers' cluster is subject to ongoing security measures which operate on routine or continuous basis.

  * Backups

    * Backups of cluster state should be taken frequently and stored for some duration.
    * The backup process for database addons must ensure that the database is consistent and in a recoverable state.[^todo-database-backups]
    * Ideally, backups can be restored by customer and cluster can be restored to any point.[^todo-backup-and-restore]

  * Updating images

    * Base images should be updated on a routine basis with the latest patches as part of the development and release pipeline.[^todo-workflow-update-image]

  * Patching

    * Before patching, a workflow should take a backup of the Caprover cluster through Caprover's backup mechanisms
    * All host instances in every cluster should be reprovisioned with latest image[^todo-workflow-update-cluster] **prefrably, but not necessarily** via 0-downtime, rolling mechanism.

  * Scanning

    * All docker containers deployed to Caprover cluster, including Caprover itself, should be routinely inspected for vulnerabilities via an automated process.
    * All hosts should be virus scanned and secured against malware execition by running CrowdStrike Falcon agent. [^todo-virus-scan-and-crowdstrike-config]
    * Vulnerability scanners should also scan open ports/services on the Caprover cluster.
    * Results should be delivered to customer. Automated resolution can be considered, but, in most cases I expect that customer's software stacks are fragile. Resolution of maintenance issues that require downtime require an initial stake in the ground. [^todo-scanning] [^todo-customer-security-remediation-policy]

  * Confidentiality

    * NERC supports up to DSL 2. Applications requiring DSL 3 security might need to be deployed to Caprover clusters on AWS accounts instead. [^todo-dsl3]

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
* Should we assume that every customers environment should also be rebuilt upon image update? Yes [^todo-should-images-update-clusters]

### Pipeline B: Development and testing new features

* H2 is a fork of Caprover. When checking out H2 to develop on patches which will either be mainlined or kept separate, it should be easy to work on Caprover `live` within a development cluster such that development remains a low-latency endeavor. [^todo-build-developer-environment]

* The CURRENT branch of the H2 repository will be `canary`, the STABLE branch will be `stable`.  [^todo-build-developer-workflow]

* All development branches are serialized and merged into Canary via review whereas QA reviews the transition from `canary` to `stable.` [^todo-qa-process]

* Releases will be built from `canary` and `stable` based on timestamp versioning and will contain virtual machine images, docker containers, and npm package as artifacts. [^todo-which-artifacts-should-be-included]

## Migration and development plan

### Goal

* I want to move every application from Heroku to Caprover in OpenStack.

* Each application and add-ons can be migrated (duplicated) programmatically. [^todo-heroku-to-caprover-app-transition-pipeline]

* All applications migrated should also have their PIEs perform any required documentation if they wish to continue service. [^todo-migrate-customers-from-heroku]

### Y22 Q4

#### Duplicate `evalue.hmdc.harvard.edu`

* evalue.hmdc.harvard.edu resides on Heroku and is a simple application developed by a researcher who no longer works at Harvard. We are maintaining an ancient version of this website by request as it is still heavily used by the researcher's community.
  
* My stake: Migrating this application onto an H2 cluster by EOY Y22 (with shortcuts) to determine overall techncal feasibility.[^todo-y22-q4-goal]

### Y23 Q1

#### Build H2 deployment workflow

* Given tuple `(PIE,project_name)` produce an H2 cluster for PIE[^todo-y23-q1-goal]

[^todo-ingestion-form]: x
[^todo-ingestion-security-review]: x
[^todo-create-coldfront-resources-for-pie]: x
[^todo-ops-access]: x
[^detail-wildcard-domain]: x
[^detail-terraform-set-cname-to-lb-or-instance-group]: x
[^todo-onboarding-welcome]: x
[^todo-determine-backup-policy-addons]: x
[^todo-relationship-to-nerc]: x
[^todo-migrate-customers-from-heroku]: x
[^todo-create-h2-development-cluster]: x
[^todo-heroku-to-caprover-app-transition-pipeline]: x
[^todo-which-artifacts-should-be-included]: x
[^todo-qa-process]: x
[^todo-build-developer-workflow]: x
[^todo-build-developer-environment]: x
[^todo-should-images-update-clusters]: x
[^todo-scaling-1to1-proj-openstack]: x
[^todo-customer-security-remediation-policy]: x
[^todo-dsl3]: x
[^todo-workflow-update-image]: x
[^todo-create-minimal-user-access]: x
[^todo-scanning]: x
[^todo-workflow-update-cluster]: x
[^todo-terraform-automation]: x
[^todo-terraform-state-management]: x
[^todo-database-backups]: x
[^todo-backup-and-restore]: x
[^todo-create-service-accounts]: x
[^todo-virus-scan-and-crowdstrike-config]: x
[^todo-y23-q1-goal]: x
[^todo-y22-q4-goal]: x
[^todo-determine-addon-requirements]: x
