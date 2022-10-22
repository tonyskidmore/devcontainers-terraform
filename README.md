# devcontainers-terraform

## Overview

This repository contains a Dockerfile used to build a container image that can be used for terraform related activities, such as using as a [Visual Studio Code devcontainer](https://code.visualstudio.com/docs/remote/containers).  

The container image is built using [GitHub Actions](https://github.com/tonyskidmore/devcontainers-terraform/actions) and is hosted as [GitHub Container Registry package](https://github.com/tonyskidmore/devcontainers-terraform/pkgs/container/azure-tools).

The container image can be pulled as follows:

````bash

docker pull ghcr.io/tonyskidmore/devcontainers-terraform:latest

````
