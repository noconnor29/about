#  about.noconnor.io
[![Deploy Infrastructure](https://github.com/noconnor29/about/actions/workflows/build_infra.yml/badge.svg)](https://github.com/noconnor29/about/actions/workflows/build_infra.yml)
[![Deploy Site](https://github.com/noconnor29/about/actions/workflows/deploy_web_app.yml/badge.svg)](https://github.com/noconnor29/about/actions/workflows/deploy_web_app.yml)


Welcome to my "About Me" site for the Cloud Resume Challenge! This repository contains the code and resources used in my site.
- [Overview](#overview)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Deployment](#deployment)

## Overview

The [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/azure/) is a project designed to help individuals build and showcase their cloud skills by creating an interactive online resume. This repository represents my personal journey through the challenge, demonstrating my proficiency in cloud technologies.

## Technology Stack

- HTML5, CSS, JavaScript - site content
- Terraform and Terraform Cloud - infrastructure-as-code (IaC)
- Azure - Static Web Apps, CosmosDB, Functions
- Cloudflare - DNS services with API control
- Python - Visitor counter API
- GitHub Actions - CI/CD for testing and deployment

## Features

- **Interactive Resume**: A dynamic and user-friendly web page showcasing my skills, experience, and projects.
- **Cloud Integration**: Demonstrates the use of cloud services to host and deploy the site.
- **Continuous Integration/Continuous Deployment (CI/CD)**: Utilizes CI/CD pipelines for automated testing, building, and deployment.
- **Responsive Design**: Ensures a seamless experience across various devices and screen sizes.


## Deployment

The deployment of this project is automated using GitHub Actions. Whenever changes are pushed to the main branch, the CI/CD pipeline is triggered, redeploying the site. 

## Next Steps
- complete work on visitor counter function (javascript, python API, CosmosDB)
- document the project!
- get some cool icons for this readme
