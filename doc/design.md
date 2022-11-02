# H2 proposed design

## Origination

[hmdc/DevOpsProjects#801](https://github.com/hmdc/DevOpsProjects/issues/801)

## Synopsis

* IQSS provides qualified Harvard-affiliated customers access to a Heroku enterprise account subscription by request.

* Heroku is a platform as a service (PaaS).

* A PaaS allows developers to quickly self-publish web applications/sites by subtracting from developer or institutional consideration everything unrelated to development: Heroku manages all physical and virtual servers, security patching, updates, monitoring, and operational checks. However, it is closed source and cost-prohibitive.
  
* [Caprover](https://github.com/caprover/caprover) is a open source PaaS developed and financially supported by an active community.
  * Apache 2.0 license
  * 9,400 stars on GitHub
  * Uses "Docker swarm" (simpler alternative to Kubernetes) to manage app deployment across multiple servers
  * Single user
  * Frontend and Caprover api server written in TypeScript

* I will replace the functionality of Heroku enterprise by building a Caprover[^caprover-origin] virtual environment for each project currently hosted on Heroku: **H2** for short. 
  
* I intend to host all virtual environments on [NERC's OpenStack platform](https://nerc.mghpcc.org/).

* IQSS will be able to maintain the same level of access and usage control over customer projects or assigned resources provided by Heroku in the new Caprover environments:
  * NERC is fully integrated into Harvard Key which will permit a seamless login (authentication) experience for Heroku users.[^heroku-has-harvard-key]
  * In addition, NERC hosts a *ColdFront* installation which manages usage and access to OpenStack resources on the basis of a project group sponsored by a principal investigator or equivalent role (PIE).
  * As all Heroku projects require sponsorship by PIE as well, I can map all Grouper[^grouper] access controls to ColdFront access controls to ensure continuity of authorization: Users in a project group on Heroku will be able to perform equivalent actions on their Caprover project limited by their access scope within the project.

## Running H2 in development *WIP*

* As of 10/24/2022, the H2 dev environment consists of 1 caprover node. [^fixme-1]
* Install [VirtualBox](https://www.virtualbox.org/) and [Vagrant](https://www.vagrantup.com/docs/provisioning/docker)
* Follow instructions in the repository: <https://github.com/hmdc/h2/tree/main/test/caprover>

## Resources required per project in production

### Wildcard domains

* A H2 user is part of a project which can contain multiple applications.
* Each application which exposes an HTTP service (a web site) requires a valid FQDN.
* Each HTTP application in H2 is required[^fixme-2] to use an SSL certificate.
* Harvard application developers usually provide their own certificates or we can use our wildcard certificate for *.hmdc.harvard.edu. But, in this scenario, PIEs own their own clusters to a larger extent than they do on Heroku - we do not want PIEs to be able to see the wildcard `*.hmdc.harvard.edu` SSL cert.
* Fist, we should register a wildcard CNAME for each customer as part of the signup process, such as `*.cga.apps.iq.harvard.edu`, to CGA's H2 caprover instance. I am not totally clear on how this should be done programmatically - through a DNS service in OpenStack (more likely) or asking HUIT for an API.
* Generate wildcard comodo certificates for `*.{customer}.apps.iq.harvard.edu`.
  
  ```bash
  *.hmdc.apps.iq.harvard.edu
  *.hmdc.apps.hmdc.harvard.edu
  *.cga.apps.iq.harvard.edu
  *.cga.apps.hmdc.harvard.edu
  ```

* I included both IQ and HMDC as I am not sure which should be used for this project as examples.


## Random

* How Caprover manages certs: Demands LetsEncrypt app. I needed to overwrite the NGINX template included in the container to incorporate our certs. LetsEncrypt is not useful for dev environments because it requires a public HTTPS port to verify that you actually own the FQDN you're requesting a free SSL cert for. This approach of overwiritng NGINX is endorsed by the Caprover maintainer but it appears to fiddle with the UI a bit? We will have to account for that eventually. [^1]

* I think most people should use the GitHub docker registry, but, Caprover also provides its own self-hosted registry which can be backed up automatically according to Docker documentation [^3]


## Pipeline from Git to OpenStack

* I want to build OpenStack virtual machine images pre-populated with Caprover, that, when deployed, possibly within an autoscaling group, into an OpenStack subnet will self-assemble into a docker swarm cluster.

Packer -> OpenStack -> Customer's OpenStack environment
       -> Vagrant (local environments)

* Packer builds the Caprover image and deploys them to both Vagrant and OpenStack. This can be automated such that when we release new virtual machine images (upgrades) they can be tested with Vagrant and then deployed to OpenStack

* There are ways we can painlessly upgrade customers' environments or allow them the choice of an A and B environment, but, this is an advanced scenario

## A customer

## Advanced issues or topics of discussion

* I've outlined an architecture I will start building which I believe can form the basis of quick development and produce a meaningful "demo" environment a customer can use, but, we still need to determine, on the basis of this, work, the following questions:[^note]

  * How thoroughly to we manage customer environments?

* Heroku provides security through performing critical OS level package upgrades when externally facing vulnerabilities are apparent or something reaches an end of life status.

We should at least provide the following

* OS level package upgrades through images or ssh: we can perform with a cluster wide `docker swarm execution` and parse the output. This could actually affect uptime depending on what is upgraded, but, less likely so and I think that is OK to do in the immediate term.

* Harvard HTTP security scans

Do we need to manage anything inside the containers deployed? I think it is fair to vuln. scan all externally facing services users deploy and are available to the Internet and even fair to use active measures against all our customers' apps if we really need to ensure data safety, but, I don't think we can realistically police customers' stacks if their internally exploitable components are never able to be publically executed.

* How do we backup and what do we backup?

We would be backing up Caprover, which has its own defined backup process, but, also potentially a docker image registry and any other add-ons a user has accumulated.

## Add-ons

* For which add-ons like MongoDB or SQL will we want to provide a higher level of support for?
* Which add-ons will we provide no formal support for?

## Development

* We can contribute to Caprover development. A simple task would be to fix Caprover such that it would allow you to define certificates w/o LetsEncrypt. I investigated the amount of work which would be necessary to make this code change and it appears trivial. Here Caprover developers hardcode LetsEncrypt as only option.

```JavaScript
    getSslCertPath(domainName: string) {
        const self = this
        return (
            CaptainConstants.letsEncryptEtcPathOnNginx +
            self.certbotManager.getCertRelativePathForDomain(domainName)
        )
    }
```

[^caprovercode]

* There's a lot of spelling mistakes.

### Other (more difficult) places to dig in

* Caprover REST APIs execute code that can potentially take a long time and time out

  * If you interrupt the browser's HTTP request when you are creating or adding a new add-on, it could potentially cause things to break in mysterious ways as components would only be half submitted to Docker swarm potentially. Caprover even warns you of that.

  * Long-running tasks should be delegated to an executor. In this case, I think it can easily be delegated to a system task on the docker swarm cluster itself.

[^1]: https://github.com/caprover/caprover/issues/1490
[^grouper]: Harvard University's Grouper installation provides authorization as a service for Harvard Key-enabled applications. IQSS uses Grouper to define access controls for Heroku projects on the basis of groups of Harvard Key identities (users).
[^3]: https://docker-docs.netlify.app/ee/dtr/admin/disaster-recovery/create-a-backup/#backup-dtr-metadata
[^note]: if there are any Harvard policies which decide for us on any one question please include those in the Chat so I can footnote them.
[^caprovercode]: <https://github.com/caprover/caprover/blob/e23b3c7d8af103c6c6dc4cea2973737daabf6e22/src/user/system/LoadBalancerManager.ts>
[^heroku-has-harvard-key]: All current Heroku users at Harvard login to Heroku via Harvard Key.
[^caprover-origin]: I evaluated a number of different solutions and arrived at Caprover as part of https://github.com/hmdc/DevOpsProjects/issues/801
[^fixme-1]: https://github.com/hmdc/DevOpsProjects/issues/810
[^fixme-2]: Link to SSL in HUIT