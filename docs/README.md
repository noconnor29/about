#  About: about.noconnor.io
[![Deploy Infrastructure](https://github.com/noconnor29/about/actions/workflows/build_infra.yml/badge.svg)](https://github.com/noconnor29/about/actions/workflows/build_infra.yml)
[![Deploy Site](https://github.com/noconnor29/about/actions/workflows/deploy_web_app.yml/badge.svg)](https://github.com/noconnor29/about/actions/workflows/deploy_web_app.yml)


I am building this site to demonstrate skills with cloud technologies and to get some Azure experience for my day job. I always learn best when I have a project or problem which I can apply new skills to so I found the [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/azure/) and dove in. I'm not done yet but it's already been a challenging but fun experience. 

- [How it works](#How-it-works)
- [Deciding on a Technology Stack](#Deciding-on-a-Technology-Stack)
- [Features](#Features)
- [Deployment](#Deployment)

## How it works
Everything that is [about.noconnor.io](https://about.noconnor.io) is contained in my GitHub repository and can be bootstrapped from scratch in a few minutes. Terraform sets up all the resources in Azure and Cloudflare and then kicks off the deployment of site content.

When changes are made to the repository, the whole process repeats and new changes are deployed into a testing environment. Once tested and reviewed, those changes are commited to the 'main' branch of the repository and are then implemented into the production environment. 

## Deciding on a Technology Stack
I chose Azure as my cloud provider but then needed to make a decision about supporting technolgies. I don't mind spending a little money on passion projects, but I didn't want significant recurring costs so this project keeps within Azure's Free Tier.

Knowing my constraints, I broke down my project into elements:
- the site and its content.
- a counting function, API, and database for vistor counting
- infrastructure, secrets, and state management 
- version control and code testing and deployment

When building a static site, HTML, CSS and JavaScript are the obvious choices. Azure Static Web Apps provided me with an cheap and cheerful way to deploy the site directly from version control.

For the visitor counter, the Azure products are also pretty straightforward. Functions is a good offering for a serverless Python API which is free under my expected load. Likewise, CosmosDB is a NoSQL database for me to store site vists and is, again, free for my expected usage. If my site became wildly popular, both aspects could scale up and out as needed to maintain funtionality.  

To build the my prodution and test environments, I landed on Terraform. I always prefer open solutions so to use it intead of native but proprietary Azure Resource Manager (ARM) templates. I also chose to use Terraform Cloud so I could update the site from anywhere and to give me flexibility for secrets management in my CI/CD pipeline. 

Several choices were also bourne out of familiarity. I already use Cloudflare for DNS and they have an excellent API and Terraform Providers, so that was my first choice for my site's DNS. Likewise, GitHub and GitHub Actions provide a unified version control and pipeline service so I saw no need to change. 

## Features

- **Interactive Resume**: A dynamic and user-friendly web page showcasing my skills, experience, and projects. Ensures a seamless experience across various devices and screen sizes.
- **Cloud Integration**: Demonstrates the use of cloud services to host and deploy the site.
- **Continuous Integration/Continuous Deployment (CI/CD)**: Utilizes CI/CD pipelines for automated testing, building, and deployment.

## Security

So I'm a security engineer. What security controls are in place here? Well, like any good security implementation, the security is baked in from the start and are present at many levels. But this is also a public site and doesn't host any critical data or processing so a measured approach is warranted.

- All credentials are scoped as closely as possible. The Cloudflare credentials can only control the relevant domain. Azure assets are split into production and test subscriptions and have service principals unique to each environment.
- Variables are shared to prevent drift. Secrets are encrypted and managed within their respective environments.
- The count database can only be accessed by my API function (in development)
- To be continued...


