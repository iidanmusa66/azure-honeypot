# Vulnerable Honeypot & Attack Surface

## Overview
This lab simulates a vulnerable "Target" environment for Red Team operations and Penetration Testing. It automates the deployment of a Linux Virtual Machine exposed to the public internet.

It utilizes **Cloud-Init (User Data)** to bootstrap the server, automatically installing an Apache Web Server and deploying a custom "Defaced" HTML page upon first boot.

## Architecture
* **Virtual Machine:** Ubuntu 18.04 LTS.
* **Networking:** Custom VNet, Public IP, and Network Security Group (NSG).
* **Automation:** Bash scripts injected via Terraform `custom_data` to handle configuration management.
* **Security:** Intentionally weak NSG rules (Allow All Inbound on Port 22 and 80) for educational simulation.

## Technologies
* Terraform
* Bash Scripting (Automation)
* Azure Compute (VM)
* Linux System Administration

## How to Use
1.  Run `terraform apply`.
2.  Copy the `public_ip_address` output.
3.  **Web Verification:** Visit `http://<IP>` to see the defaced website.
4.  **SSH Access:** Log in via `ssh adminuser@<IP>` to simulate an attacker gaining root access.
