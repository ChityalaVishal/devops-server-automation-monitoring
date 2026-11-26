# Automated Server Provisioning, Configuration Management and Monitoring Using DevOps Tools

## 1. Project Overview

This project demonstrates the implementation of DevOps practices for server provisioning, configuration management, application deployment, continuous integration, and infrastructure monitoring.

We use three Ubuntu EC2 instances hosted on Amazon Web Services (AWS). One instance acts as the Master Server, while the other two act as Agent Servers.

Different DevOps tools are integrated to automate server configuration, deploy an Apache web server, monitor server availability, and validate configuration files through GitHub Actions.

## 2. Project Objectives

- Automate server configuration using Puppet.
- Automate application deployment using Ansible.
- Retrieve and inspect AWS infrastructure information using Terraform.
- Monitor server availability using Nagios.
- Maintain project files using Git and GitHub.
- Implement automated configuration validation using GitHub Actions.

## 3. Technologies Used

| Technology | Purpose |
|---|---|
| AWS EC2 | Cloud infrastructure |
| Ubuntu Linux | Operating system |
| Terraform | Infrastructure inspection |
| Puppet | Configuration management |
| Ansible | Server automation and deployment |
| Nagios | Infrastructure monitoring |
| Git | Version control |
| GitHub | Source code repository |
| GitHub Actions | Continuous integration |

## 4. Project Architecture

The project uses three Ubuntu EC2 instances.

### Master Server
The Master Server hosts:
- Puppet Server
- Ansible
- Terraform
- Nagios Core
- Git

### Agent Server 1
- Ubuntu Linux
- Puppet Agent
- Apache Web Server

### Agent Server 2
- Ubuntu Linux
- Puppet Agent
- Apache Web Server

The Master Server communicates with both Agent Servers through their private IP addresses.

## 5. AWS Infrastructure Setup

### Step 1: Create EC2 Instances

1. Log in to the AWS Management Console.
2. Open the EC2 service.
3. Launch three Ubuntu Server instances.
4. Use the same VPC for all three instances.
5. Configure the required security group rules.
6. Connect to the Master and Agent instances using SSH.

The instances are configured as follows:

| Instance | Role | Instance Type |
|---|---|---|
| DevOps-Master | Central management server | t3.small |
| Puppet-Agent-1 | Managed web server | t3.micro |
| Puppet-Agent-2 | Managed web server | t3.micro |

### Step 2: Configure Hostnames

Add the following entries to `/etc/hosts` on all three instances:

```text
172.31.15.40 puppet-master
172.31.41.212 puppet-agent-1
172.31.47.34 puppet-agent-2
```

These entries allow the servers to communicate using hostnames.

Verify connectivity from the Master Server:

```bash
ping -c 4 puppet-agent-1
ping -c 4 puppet-agent-2
```

## 6. Puppet Configuration Management

### Step 1: Install Puppet Server

Install and configure Puppet Server on the Master Server.

Check the installed version:

```bash
puppetserver --version
```

### Step 2: Install Puppet Agents

Install Puppet Agent on both Agent Servers.

Check the Puppet version:

```bash
puppet --version
```

### Step 3: Configure Agent Certificates

Configure both agents to communicate with the Puppet Master using the hostname `puppet-master`.

On the Master Server, inspect pending certificate requests:

```bash
sudo puppetserver ca list
```

Sign the agent certificates:

```bash
sudo puppetserver ca sign --all
```

### Step 4: Create the Puppet Manifest

Create the manifest on the Master Server:

```bash
sudo nano /etc/puppet/code/environments/production/manifests/site.pp
```

Configuration:

```puppet
node 'puppet-agent-1', 'puppet-agent-2' {
  package { 'apache2':
    ensure => installed,
  }

  service { 'apache2':
    ensure  => running,
    enable  => true,
    require => Package['apache2'],
  }

  file { '/var/www/html/index.html':
    ensure => file,
    content => '<h1>DevOps Automation Project</h1><p>Apache managed by Puppet</p>',
    require => Package['apache2'],
  }
}
```

### Step 5: Validate the Manifest

Run on the Master Server:

```bash
sudo puppet parser validate /etc/puppet/code/environments/production/manifests/site.pp
```

### Step 6: Apply Puppet Configuration

Run the following command on each Agent Server:

```bash
sudo puppet agent -t
```

Verify Apache:

```bash
sudo systemctl status apache2
```

Expected result: Apache should be installed and running on both Agent Servers.

## 7. Ansible Automation

### Step 1: Install Ansible

Install Ansible on the Master Server.

Verify the installation:

```bash
ansible --version
```

### Step 2: Configure SSH Authentication

Generate an SSH key pair on the Master Server:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/ansible_key2
```

Add the public key to both Agent Servers' `~/.ssh/authorized_keys` files.

Test SSH connectivity:

```bash
ssh -i ~/.ssh/ansible_key2 ubuntu@172.31.41.212
ssh -i ~/.ssh/ansible_key2 ubuntu@172.31.47.34
```

### Step 3: Configure Ansible Inventory

Edit the inventory file:

```bash
sudo nano /etc/ansible/hosts
```

Add:

```ini
[webservers]
agent1 ansible_host=172.31.41.212
agent2 ansible_host=172.31.47.34

[webservers:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/ubuntu/.ssh/ansible_key2
ansible_python_interpreter=/usr/bin/python3
```

### Step 4: Test Agent Connectivity

```bash
ansible webservers -m ping
```

Expected result: Both agents should return a successful ping response.

### Step 5: Create the Ansible Playbook

Create the playbook in the project repository:

```bash
nano ansible/apache.yml
```

Configuration:

```yaml
---
- name: Install and configure Apache webservers
  hosts: webservers
  become: yes

  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
        update_cache: yes

    - name: Ensure Apache is running
      service:
        name: apache2
        state: started
        enabled: yes

    - name: Deploy webpage using Ansible
      copy:
        content: |
          <html>
          <head><title>DevOps Automation</title></head>
          <body>
          <h1>Automated Deployment Successful!</h1>
          <p>This webpage was deployed using Ansible.</p>
          <p>Server managed by our DevOps automation project.</p>
          </body>
          </html>
        dest: /var/www/html/ansible.html
        mode: '0644'
```

### Step 6: Execute the Playbook

Run on the Master Server:

```bash
ansible-playbook ansible/apache.yml
```

Verify deployment:

```bash
curl http://172.31.41.212/ansible.html
curl http://172.31.47.34/ansible.html
```

Expected result: The deployed HTML webpage should be returned from both agents.

## 8. Terraform Infrastructure Inspection

### Step 1: Install Terraform

Install Terraform on the Master Server.

Verify:

```bash
terraform version
```

### Step 2: Configure AWS Access

An IAM role named `DevOps-Terraform-Role` is attached to the Master EC2 instance to allow Terraform to access AWS through the instance role.

Verify AWS identity:

```bash
aws sts get-caller-identity
```

Do not store AWS access keys or secret keys in the GitHub repository.

### Step 3: Create Terraform Configuration

Navigate to the Terraform directory:

```bash
cd ~/devops-server-automation-monitoring/terraform
```

The `main.tf` configuration uses the AWS provider and data sources to inspect the existing EC2 instances.

The configuration retrieves:
- AWS account ID
- Master instance ID, private IP and instance type
- Agent 1 instance ID, private IP and instance type
- Agent 2 instance ID, private IP and instance type

### Step 4: Initialize Terraform

```bash
terraform init
```

### Step 5: Format and Validate

```bash
terraform fmt
terraform validate
```

### Step 6: Generate an Execution Plan

```bash
terraform plan
```

### Step 7: Apply the Configuration

```bash
terraform apply
```

Confirm the operation when prompted.

### Step 8: Display Outputs

```bash
terraform output
```

Expected result: Terraform displays the account ID and details of the three existing EC2 instances.

**Important:** In this implementation, Terraform uses data sources to inspect existing infrastructure. It does not create or destroy EC2 instances.

## 9. Nagios Monitoring

### Step 1: Install Nagios

Install Nagios Core and the required monitoring plugins on the Master Server.

Verify the service:

```bash
sudo systemctl status nagios4
```

### Step 2: Configure Agent Hosts

Create the monitoring configuration:

```bash
sudo nano /etc/nagios4/conf.d/agents.cfg
```

Define both Agent Servers with their hostnames, aliases, private IP addresses and HTTP host checks.

### Step 3: Configure Monitoring Commands

The custom HTTP check command is defined in the Nagios commands configuration:

```cfg
define command {
    command_name    check-host-http
    command_line    $USER1$/check_http -H $HOSTADDRESS$ -p 80
}
```

This command checks whether the Apache HTTP service responds on port 80.

### Step 4: Configure Services

Configure the following monitoring services for both agents:

- PING: Checks network reachability.
- HTTP: Checks web server availability.

### Step 5: Validate Nagios Configuration

```bash
sudo nagios4 -v /etc/nagios4/nagios.cfg
```

Expected result: Configuration verification should complete with zero warnings and zero errors.

### Step 6: Restart Nagios

```bash
sudo systemctl restart nagios4
sudo systemctl status nagios4
```

### Step 7: Access the Nagios Dashboard

Open the following URL in a browser:

```text
http://<MASTER_PUBLIC_IP>/nagios4/
```

Log in using the configured Nagios administrator account.

Expected result:
- Both Agent Servers should appear as monitored hosts.
- PING checks should report their network status.
- HTTP checks should report Apache availability.

## 10. Git and GitHub Integration

### Step 1: Initialize the Repository

The project is maintained in:

```bash
cd ~/devops-server-automation-monitoring
```

Check repository status:

```bash
git status
```

### Step 2: Configure Git Identity

```bash
git config --global user.name "Vishal Chityala"
git config --global user.email "vishalchityala24@gmail.com"
```

### Step 3: Track Project Files

```bash
git add .
git commit -m "Add DevOps project files"
```

### Step 4: Push Changes to GitHub

```bash
git push origin master
```

GitHub repository:

https://github.com/ChityalaVishal/devops-server-automation-monitoring

### Step 5: Protect Sensitive Files

The `.gitignore` file excludes Terraform state files, SSH private keys and credential files.

Never commit private SSH keys, AWS credentials, access tokens or Nagios password files.

## 11. GitHub Actions Continuous Integration

Three GitHub Actions workflows are configured in:

```text
.github/workflows/
```

### 11.1 Terraform CI Pipeline

File: `.github/workflows/terraform.yml`

This workflow:
1. Checks out the repository.
2. Sets up Terraform.
3. Checks Terraform formatting.
4. Initializes Terraform without configuring a backend.
5. Validates the Terraform configuration.

### 11.2 Ansible CI Pipeline

File: `.github/workflows/ansible.yml`

This workflow:
1. Checks out the repository.
2. Sets up Python.
3. Installs Ansible Core.
4. Checks the Ansible version.
5. Performs an Ansible playbook syntax check.

### 11.3 Puppet CI Pipeline

File: `.github/workflows/puppet.yml`

This workflow:
1. Checks out the repository.
2. Installs Puppet.
3. Checks the Puppet version.
4. Validates the Puppet manifest syntax.

### Workflow Execution

Whenever changes are pushed to the `master` branch or a pull request targets it, the corresponding workflows run automatically.

The workflow results can be viewed under the **Actions** tab of the GitHub repository.

## 12. Project Verification

The following checks are used to verify the implementation:

| Component | Verification |
|---|---|
| AWS | Three EC2 instances available |
| Puppet | Agent configuration applied successfully |
| Apache | Service running on both agents |
| Ansible | Both agents respond to ping |
| Ansible | Webpage deployed on both agents |
| Terraform | Existing EC2 details displayed |
| Nagios | Both agents monitored |
| Nagios | PING and HTTP checks successful |
| GitHub Actions | Terraform, Ansible and Puppet workflows pass |

## 13. Expected Outcomes

- Successful configuration management using Puppet.
- Automated Apache deployment using Ansible.
- Inspection of existing AWS infrastructure using Terraform.
- Centralized monitoring using Nagios.
- Source code version control using Git and GitHub.
- Automated validation using GitHub Actions.

## 14. Repository Structure

```text
devops-server-automation-monitoring/
│
├── .github/
│   └── workflows/
│       ├── terraform.yml
│       ├── ansible.yml
│       └── puppet.yml
│
├── ansible/
│   └── apache.yml
│
├── nagios/
│   ├── agents.cfg
│   └── commands.cfg
│
├── puppet/
│   └── manifests/
│       └── site.pp
│
├── terraform/
│   └── main.tf
│
├── website/
├── screenshots/
├── .gitignore
└── README.md
```

## 15. Conclusion

This project demonstrates how multiple DevOps tools can work together to automate and monitor a cloud-based server environment.

Puppet maintains server configuration, Ansible automates application deployment, Terraform inspects existing AWS infrastructure, and Nagios monitors server availability. Git and GitHub provide version control, while GitHub Actions automates configuration validation.

The project provides practical experience in cloud infrastructure, Linux administration, configuration management, automation, monitoring and continuous integration.

## Author

**Vishal Chityala**

B.Tech Computer Science and Engineering

GitHub: https://github.com/ChityalaVishal
