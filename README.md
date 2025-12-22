# Windows Environment via GitHub Actions
This project provides a temporary **Windows virtual environment** running on **GitHub Actions**, with remote access using **Tailscale** and Remote Desktop (RDP).
Useful for testing, experiments, or running Windows-only tools.

## How it Works
This environment is based on the latest Windows Server image officially provided and maintained by GitHub for GitHub Actions runners.

relies on Tailscale, which uses a VPN to place the server or computer on a private network that behaves like a local network for secure communication, In our setup, we connect to the virtual machine through this network to access and control the system remotely.

## Preparing it in the repository
First, create a new workflow (Simple workflow) in your GitHub repository, and install or copy the workflow code (windows.yml) into a workflow file in your repository.

Make sure you have added your Tailscale auth key as a repository secret named TAILSCALE_AUTHKEY from
Settings > Secrets > New repository secret.

## Restrictions
Although this may be considered a free virtual environment, the session is limited to a maximum of **6 hours.**

Additionally, this usage may violate GitHub’s Terms of Service. If such activity is detected, your account may be restricted or suspended.
