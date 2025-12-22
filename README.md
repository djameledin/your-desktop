# Windows Environment via GitHub Actions
This project provides a temporary **Windows virtual environment** running on **GitHub Actions**, with remote access using **Tailscale** and Remote Desktop (RDP).
Useful for testing, experiments, or running Windows-only tools.

## How it Works
This environment is based on the latest Windows Server image officially provided and maintained by GitHub for GitHub Actions runners.

relies on Tailscale, which uses a VPN to place the server or computer on a private network that behaves like a local network for secure communication, In our setup, we connect to the virtual machine through this network to access and control the system remotely.

## Setup Instructions
Create a new workflow in your GitHub repository (e.g., .github/workflows/windows.yml).

Copy or install the workflow code into the workflow file.

Add your Tailscale auth key and password as a repository secret named "TAILSCALE_AUTHKEY" "PASSWORD" from Settings > Secrets > New repository secret

Trigger the workflow manually via the Actions tab.

## Restrictions
Although this may be considered a free virtual environment, the session is limited to a maximum of **6 hours.**

Additionally, this usage may violate GitHub’s Terms of Service. If such activity is detected, your account may be restricted or suspended.

