# TEAM 3 - Abuzzina, rink, yuxinden

***Video of Deployment*** - https://drive.google.com/file/d/1Z9tkHkghXwEcxIVrJ9pMc8EJJTqQNi8I/view?usp=sharing

## Overview
> This is our final submission for our final project. This is a small project called spring-clinic that shows what an end-to-end pipeline is like for covering CI/CD in Jenkins, SonarQube, OwaspZap, Promethus, Grafana, and deployment to a production VM Via Ansible. 

*Here is what each tool are are using does**
- **SonarQube**: Quality gate for code analysis. Sonarqube is great for shift left security because it catches bugs early in the devops pipeline. 
- **Jenkins**: CI/CD automation server. It automates everythng which allow you to make less mistakes in the pipeline. It integrates all of our tools into one place. 
- **OWASP ZAP**: Dynamic security scanning. It checks for real world vulnerablilties of our running application. 
- **Prometheus**: Metrics Collection and Monitoring of Jenkins. This allows us to see how our CL/CD pipeline is working. 
- **Grafana**: Takes Promethus to visual and create dishboards for pipeline, app, and infrastructure health. 
- **Production VM**: Target server where the Spring Petclinic app is deployed and accessed by users/tools  
- **Ansible**: Configuration management and deployment automation for Jenkins. Ensures that our depolyments are repeatable. 

## prerequisites
Virtualizer info  
	VMware workstation 17 pro  
	Version 17.6.3 build-24583834   

Virtual machine OS : ubuntu-24.04.3-live-server-amd64

> The VM is so you do not configure this project on your host machine (e.g. Windows 11, MacOS 26 Tahoe, Lindux Fedora.) In a Real CI/CD pipeline you need to have production separation so when things break or crash you do not destroy your entire machine. Also for security OWASP Zap scans and Ansible on your host OS is not recommended. 


## autoScript

See [`automation-scripts/demo.sh`](automation-scripts/demo.sh)


## vm-server-installation

#### Get a download of the Ubuntu Server 

https://ubuntu.com/download/server

(to get out of the virtual machine. hit the right control key otherwise known as the host key)
> Open your Virtual Machine and click "Create a New Virtual Machine"  
" what type of configuration do you want? Typical (Recommended)" -> hit next
"installer disc image file (iso)" -> make sure to select the correct ISO image & hit next
![InstallerdiscImagefile](image-1.png)

> "virtual Machine name" -> name it whatever you like. make sure your location of the machine is in the correct spot (its wherever on your system your vm files are stores or create a new file in your users folder for your user)

![LocationofVMmachine](image-2.png)

> Store as a single virtual disk file. Your Server should have at least 60 GB as your server will start at 8-12 GB as ready. If you can not afford to give that muc or simply do not want to. Use 35-40gb and when running this lab ensure you are running the commands found in (CleanUpTime)

> NEXT

>Click on customize hardware  
ensure that there is two CPU cores and a little more memory(ram) on your system (whatever you can afford to give)

> Click finish 

> NEXT!  
Try or install ubuntu server  

> Let the server do its thing  
English -> next
Keyboard config (leave it) Done -> next

>Ubuntu server (x) -> next
**slow down for the next part**
>Network configuration  
for some reason at this part your network configuration might not automatically configure. Use your arrow keys to enter into your ipv4 and enable automatic DHCP -> save and that should bring up your Ipv4. Your VM will switch it back to static after.

> NEXT!
You do NOT need a proxy config for this project. You only need this when you are in a corporate enviroment.

> NEXT! Ubuntu Archive Mirror for Ubuntu  
Leave this be. 

> NEXT! Guided Storage configuration 
Leave this be. DO NOT ENCRYPT FOR THIS PROJECT. Although encrypting is a good idea for protecting sensitive data at rest, we are not dealing with sensitive information or need it at this point. 

> Set your own user, pass, servername etc. (REMEMBER THIS.)

>NEXT! Storage Configuration (leave be. hit done)
![storageconfiguration(image-3.png)

>Next! Upgrade to Ubuntu Pro (Do not need. hit continue) 
![noubuntupro](image-4.png)

>NEXT! SSH Configuration  
Enable "install OpenSSH Server" BUT DO NOT import at this stage. You will do this later. 
![alt text](image-5.png)

>Feature server snaps (leave be. hit done)  
![alt text](image-6.png)

>*Done! let it run and do its thing.* Dont freak out if it says failed to mount after selecting reboot. just press enter. 

>It should look like: 
![alt text](image-7.png)

***Take a snapshot here.***

>Click this clock plus button 
![alt text](image-8.png)

## Connecting my Virtual Machine to your host machine
##### When you are configuring jenkins, zap, etc. It is is easier to copy paste our commands from our github or running scripts frpm your host terminal than just typing it out on the production server. Plus the interface is 1000% better. 

> Login to the server with your username and password you created in the step above for this server. 
 and the ip a -> this allow you to see the ip information for this server 

![alt text](image-10.png) *The ip for your server is at the inet part without the /24* 

> check if ssh is enable by running the command in your ubuntu server

```sudo systemctl status ssh``` *For sudo (super user give admin privlages) type your password for the server. thi will happen multiple times* 

![alt text](image-11.png)

> enable if not
```sudo systemctl enable ssh --now```

>Check firewall status:

```sudo ufw status```

>If it shows inactive skip this 

>If it is active, allow SSH:

```sudo ufw allow ssh```
```sudo ufw reload```

> On your windows system command line terminal "cmd"

```ssh username@VMproductionserverIp``` -> put the inet ip in there. 

>type "yes" for the fingerprint and hit enter

***you're in!***

***Take another snapshot here.***

## Fork the project repository on GitHub/GitLab and clone it to your local machine.
Things should be straight forward from here getting the project to come up. 

![alt text](image-12.png)

This is where you now run your commands unless stated otherwise. 

## pull from our git repo with docker install script first 

```sudo apt update``` -> always ensure you are up to date 

```sudo apt install -y git``` -> installing git and automatically saying yes

To create a fork you would go into the repo and create a fork by clicking on the fork button. 

![alt text](image-31.png)

Getting the clone. go to the green <> code button in our workspace github.com/rosannadeng/spring-petclinic and then grab the link in https

```sudo git clone https://github.com/rosannadeng/spring-petclinic.git```

*why would you need to fork something? It allows you to make changes without damanging or messing up the other person's repo.*

##    Use Docker to set up containers for Jenkins, SonarQube, Prometheus, Grafana, and OWASP ZAP.
## docker-setup
##### For this section: you may have issues pulling from our git hub if you do not have docker installed. In essense we are trying to pull the git repo to boot up the docker-compose file in there. Our docker will put up a container that have all of our application code, libraries, java, and config files all into our mini self contained environment. This allows us to make outr system exact the same as everyone else's. However docker compose commands will not work if docker is not on the VM. If our docker script pull did not work, here is a instructional with a script:  


> Although you just installed ubuntu run an update to ensure you are up to date  

```sudo apt update```

> I used this step-by-step to set up docker. it does a great job in explaining what a container is etc. **step 6 needs to be 

https://linuxvox.com/blog/installing-docker-on-ubuntu-server/

> dont want to learn and copy/ paste? 
here is a quick script to paste into the command line

> step 1: ```touch install_docker.sh```

> step 2: ```sudo chmod +x install_docker.sh```

> step 3: ```sudo nano install_docker.sh```

>paste this script 

```
#!/bin/bash

set -e 

sudo apt update
sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo apt install -y docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo docker run hello-world
```
> step 3: ```sudo ./install_docker.sh```


>Running into issues? possible you may need to tell ubuntu to install trusted ssl certificates so our server can get docker, but you may need to be able to add the repo for our version of ubuntu. 

```sudo apt install ca-certificates curl gnupg lsb-release```

> once> running into issues? use ```sudo chown $USER:$USER install_docker.sh``` then the sudo chmod command again. 


 you have followed through the installation until step 8:verify  install lets move on. It is good to read the entire documentation as there is good information in this. 

## docker-build-images 

> for some reason maven is going to fail. here is the owrk around for it 

```sudo mkdir -p /etc/docker```

```sudo nano /etc/docker/daemon.json```

```sudo systemctl restart docker```

```sudo docker compose build maven-java25```


Now maven should be successful

>  ```sudo docker compose up -d```

> ```sudo docker compose up petclinic```

Once you get the container to run 

check if you have all your services running with
``` sudo docker ps```

here are the websites for all the containers for if you are doing it on a VM or on local host. 

Jenkins: http://yourIP:8082/jenkins/ or http://localhost:8082/jenkins/

SonarQube: http://yourIP:9000 or http://localhost:9000

Prometheus: http://yourIP:9090 or http://localhost:9090

Grafana: http://yourIP:3030 or http://localhost:3030

Offical PetClinc Site: http://yourIP:8081/ or http://localhost:8081/

*note: the petclinic section in your docker-compose.yml may be different due to updates <-ensure you are getting the most rescent tag from this repo * *https://hub.docker.com/r/springcommunity/spring-petclinic*

 >petclinic:
    image: springcommunity/spring-petclinic:3.5.6
    container_name: petclinic
    ports:
      - "8081:8080"
    networks:
      - devops-net

Complete CI/CD Pipeline Setup Guide for Spring PetClinic
A step-by-step guide

What You'll Build
A complete DevOps pipeline with:

Jenkins (CI/CD automation)
SonarQube (Code quality analysis)
OWASP ZAP (Security scanning)
Prometheus (Metrics collection)
Grafana (Monitoring dashboards)
Prerequisites
Required Software
Docker Desktop

Install and start Docker Desktop
Verify installation:
docker --version
docker compose version
You version returned
Git

Verify installation:
git --version
Step-by-Step Setup
Step 1: Get the Code
Open your terminal run:

cd ~/Documents

git clone https://github.com/rosannadeng/spring-petclinic.git

cd spring-petclinic

# Verify you're in the right place
ls -la
Step 2: Build Custom Docker Images
build two custom Docker images before starting services.

2.1 Build Jenkins Image with Docker CLI and plugins
# Build Jenkins image from Dockerfile.jenkins
docker compose build jenkins
2.2 Build Maven-Java25 Image
# Build Maven with Java 25 image
docker compose build maven-java25
2.3 Verify Images Were Built
# Check that images were created
docker images | grep -E "jenkins|maven-java25"
Step 3: Start All Services
# Start all services in detached mode (background)
docker compose up -d
What this does: Starts containers for Jenkins, SonarQube, PostgreSQL, Prometheus, and Grafana.

3.1 Verify All Services Are Running
# Check running containers
docker compose ps
Step 4: Configure SonarQube
4.1 Access SonarQube Web Interface
Open your web browser
Go to: http://localhost:9000
Wait for SonarQube to fully start
4.2 Initial Login
Username: admin
Password: admin
Click "Log in"
4.3 Change Password
Enter:
Old password: admin
New password: (choose a strong password)
Confirm password: (same password)
4.4 Generate Authentication Token
Click on your profile icon (top right corner, letter 'A')
Select "My Account"
Click on the "Security" tab
Under "Generate Tokens":
Name: jenkins
Type: Select "Global Analysis Token"
Expires in: Select "No expiration"
Click "Generate"
CRITICAL: You'll see a token like squ_xxxxxxxxx
Copy this tokeny
Save it in a somewhere
Step 5: Create Environment File with Token
5.1 Create .env File
In your terminal, run:

# Make sure you're in the project directory
cd ~/Documents/spring-petclinic

# Create .env file with your token
cat > .env << 'EOF'
SONAR_AUTH_TOKEN=PASTE_YOUR_TOKEN_HERE
EOF
Replace PASTE_YOUR_TOKEN_HERE with your actual token from Step 4.4

Example:

cat > .env << 'EOF'
SONAR_AUTH_TOKEN=squ_1234567890abcdefghijklmnop
EOF
5.2 Verify .env File
### Check the file was created
cat .env
### should be the same as you have
5.3 Restart Services to Load Token
# Stop all services
docker compose down

### Start services again (they'll read the .env file)
docker compose up -d

5.4 Verify Token Was Loaded
### Check if Jenkins has the environment variable
docker exec jenkins env | grep SONAR_AUTH_TOKEN

### You should see:
### SONAR_AUTH_TOKEN=squ_your_actual_token
Step 6: Configure Jenkins
6.1 Access Jenkins Web Interface
Open your web browser
Go to: http://localhost:8082/jenkins
You'll see "Unlock Jenkins" page
6.2 Get Initial Admin Password
In your terminal, run:

# Get the initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
Expected output: A long string like a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6

Copy this password
Paste it into the Jenkins "Administrator password"
6.3 Install Plugins
Select "Install suggested plugins"
6.4 Instance Configuration
Jenkins URL: Keep default http://localhost:8082/jenkins/
Click "Save and Finish"
Click "Start using Jenkins"
6.5 Configure SonarQube Server in Jenkins
Option A: Verify Automatic Configuration (Recommended)

Go to "Manage Jenkins" (left sidebar)
Click "Configure System"
Scroll down to "SonarQube servers" section
You should see:
Name: SonarQubeServer
Server URL: http://sonarqube:9000
Server authentication token: sonar-token
If you see this, skip to next. If not, continue with Option B.

Option B: Manual Configuration

Go to "Manage Jenkins" → "Configure System"
Scroll to "SonarQube servers"
Click "Add SonarQube"
Fill in:
Name: SonarQubeServer
Server URL: http://sonarqube:9000
Server authentication token: Click "Add" → "Jenkins"
In the popup:
Kind: Select "Secret text"
Scope: Global
Secret: Paste your SonarQube token from Step 4.4
ID: sonar-token
Description: SonarQube Authentication Token
Click "Add"
Select sonar-token from the dropdown
Click "Save" at the bottom
6.6 Verify Tools Configuration
Go to "Manage Jenkins" → "Global Tool Configuration" or "Tools" (in the new Jenkins UI)
Verify you see:
Maven installations: Maven 3.9.5
JDK installations: JDK 25
These are auto-configured by jenkins.yaml.

Step 7: Create Jenkins Pipeline
7.1 Create New Pipeline Job
From Jenkins homepage, click "New Item"
Enter item name: spring-petclinic-pipeline
Select "Pipeline"
Click "OK"
7.2 Configure Pipeline Source
Scroll down to the "Pipeline" section:

Definition: Select "Pipeline script from SCM"
SCM: Select "Git"
Repository URL: Enter your repository URL
Example: https://github.com/rosannadeng/spring-petclinic.git
Credentials: Leave as "- none -" (for public repos)
Branch Specifier: */main
Script Path: Jenkinsfile
Click "Save"
Step 8: Run Your First Build
8.1 Trigger Build
Click "Build Now" (left sidebar)
You'll see a build appear in "Build History"
Click on the build number (e.g., #1)
8.2 Watch Build Progress
Option A: Classic View

Click on the build number
Click "Console Output" to see real-time logs
Option B: Blue Ocean (Recommended)

Click "Open Blue Ocean" (left sidebar)
You'll see a visual pipeline with stages
8.3 Build Stages
The pipeline will execute these stages (takes 15-20 minutes on first run):

Checkout - Downloads code from Git
Build (Java 25) - Compiles the application
Test (Java 25) - Runs unit tests
SonarQube Analysis - Analyzes code quality
Quality Gate - Waits for SonarQube results
Checkstyle - Checks code style
Package - Creates JAR file
Archive - Saves artifacts
OWASP ZAP Scan - Security scanning
Publish ZAP Report - Publishes security report
8.4 Monitor Build
### In another terminal, watch Jenkins logs
docker logs -f jenkins

### Watch SonarQube logs
docker logs -f sonarqube
Step 9: View Results
9.1 View SonarQube Analysis
Go to http://localhost:9000
Click on "spring-petclinic" project
View:
Bugs: Code issues that could cause errors
Vulnerabilities: Security issues
Code Smells: Maintainability issues
Coverage: Test coverage percentage
Duplications: Duplicate code
9.2 View OWASP ZAP Security Report
In Jenkins, click on your job
Click "OWASP ZAP Security Report" (left sidebar)
9.4 View Test Results
In Jenkins build page
Click "Test Result" (left sidebar)
See:
Total tests
Passed tests
Failed tests
Test duration
9.5 View Code Coverage
In Jenkins build page
Click "Coverage Report" (left sidebar)
See JaCoCo coverage report with line/branch coverage
Symptoms: Jenkins container keeps restarting

Solution:

Understanding the Pipeline
What Each Stage Does
Checkout

Downloads code from Git repository
Build (Java 25)

Compiles Java source code
Downloads Maven dependencies (slow on first run)
Test (Java 25)

Runs JUnit tests
Generates test reports
SonarQube Analysis

Analyzes code quality
Finds bugs, vulnerabilities, code smells
Calculates test coverage
Quality Gate

Waits for SonarQube to finish processing
Checks if code meets quality standards
Fails build if quality gate fails
Checkstyle

Checks code formatting and style
Generates warnings for style violations
Package

Creates executable JAR file
Archive

Saves JAR file as Jenkins artifact
OWASP ZAP Scan

Starts application in Docker
Scans for security vulnerabilities
Tests for common web vulnerabilities (XSS, SQL injection, etc.)
Publish ZAP Report

Makes security report available in Jenkins
Total Build Time
First build: 15-20 minutes (downloading dependencies)
Subsequent builds: 5-10 minutes
Additional Resources
Access URLs
Jenkins: http://localhost:8082/jenkins
SonarQube: http://localhost:9000
Prometheus: http://localhost:9090
Grafana: http://localhost:3000
Application (when running): http://localhost:8080
Default Credentials
Service	Username	Password
SonarQube	admin	admin (change on first login)
Grafana	admin	admin
Jenkins	(you create)	(you create)
Documentation
Jenkins: https://www.jenkins.io/doc/
SonarQube: https://docs.sonarqube.org/
OWASP ZAP: https://www.zaproxy.org/docs/
Docker Compose: https://docs.docker.com/compose/

# Ansible Deployment Instructions

## What We Did

Set up automated deployment from Jenkins to a production server using Ansible. When you push code to GitHub, Jenkins automatically builds, tests, and deploys the application.

## Prerequisites

- Jenkins running with Ansible installed
- Production server accessible via SSH
- Docker installed (for testing locally)

## Files Created

1. **Dockerfile** - Builds the application container
2. **ansible/inventory/hosts** - Lists production servers
3. **ansible/deploy.yml** - Ansible playbook for deployment
4. **ansible/templates/petclinic.service.j2** - Systemd service template
5. **Jenkinsfile** - Added deployment stage

## Step-by-Step Setup

### 1. Update Inventory File

Edit `ansible/inventory/hosts` to point to your production server:

```ini
[production]
production_server ansible_host=YOUR_VM_IP ansible_user=YOUR_USER ansible_ssh_private_key_file=~/.ssh/id_rsa
```

Replace:
- `YOUR_VM_IP` with actual IP (e.g., `192.168.1.100`)
- `YOUR_USER` with SSH username (e.g., `ubuntu`)

### 2. Setup SSH Access

From Jenkins server, test SSH connection:

```bash
ssh YOUR_USER@YOUR_VM_IP
```

If prompted for password, setup key-based auth:

```bash
ssh-copy-id YOUR_USER@YOUR_VM_IP
```

### 3. Rebuild Jenkins Image

Jenkins needs Ansible installed:

```bash
cd /path/to/spring-petclinic
docker compose build jenkins
docker compose up -d jenkins
```

### 4. Test Deployment Manually

Before running through Jenkins, test Ansible deployment:

```bash
# Build the JAR
./mvnw clean package -DskipTests

# Run Ansible playbook
ansible-playbook -i ansible/inventory/hosts ansible/deploy.yml
```

### 5. Commit and Push Changes

```bash
git add .
git commit -m "Add Ansible deployment to production"
git push origin ansible-deployment
```

Or merge to main:

```bash
git checkout main
git merge ansible-deployment
git push origin main
```

### 6. Verify Jenkins Auto-Deploy

1. Go to Jenkins: http://localhost:8082/jenkins
2. Click on your pipeline job
3. Watch the build run automatically (polls every minute)
4. Check the "Deploy to Production" stage completes successfully

### 7. Verify Application Running on Production

Check the application is running:

```bash
# From production server
curl http://localhost:8080

# Or from browser
http://YOUR_VM_IP:8080
```

You should see the welcome page with: **"Deployed via Jenkins + Ansible CI/CD Pipeline"**

## Testing the Full CI/CD Pipeline

### Make a Code Change

1. Edit `src/main/resources/templates/welcome.html`
2. Change the deployment message to something unique:
   ```html
   <p style="color: #28a745; font-weight: bold;">Updated at [YOUR_TIMESTAMP]</p>
   ```

3. Commit and push:
   ```bash
   git add src/main/resources/templates/welcome.html
   git commit -m "Update welcome message for deployment test"
   git push origin main
   ```

4. Wait 1 minute for Jenkins to poll and trigger build

5. Watch Jenkins pipeline:
   - Checkout → Build → Test → SonarQube → Quality Gate → Package → Archive → Security Scan → **Deploy**

6. Verify on production:
   - Open http://YOUR_VM_IP:8080
   - Check for your updated message

## Verification Checklist

- [ ] Ansible playbook runs successfully
- [ ] Application deploys to production server
- [ ] Application accessible at http://YOUR_VM_IP:8080
- [ ] Welcome page shows deployment message
- [ ] Code change triggers Jenkins build automatically
- [ ] New version deploys without manual intervention
- [ ] Updated content visible on production server

## Troubleshooting

### Ansible Connection Failed

```bash
# Test SSH connection
ansible production -i ansible/inventory/hosts -m ping

# Expected output:
# production_server | SUCCESS => {
#     "ping": "pong"
# }
```

### Application Won't Start

Check logs on production server:

```bash
ssh YOUR_USER@YOUR_VM_IP
sudo systemctl status petclinic
sudo journalctl -u petclinic -f
```

### Jenkins Can't Find Ansible

Rebuild Jenkins image with Ansible:

```bash
docker compose build jenkins
docker compose restart jenkins
```

### Port Already in Use

Stop existing process:

```bash
ssh YOUR_USER@YOUR_VM_IP
sudo systemctl stop petclinic
# or
sudo pkill -f petclinic
```

## Production Server Details

- **Application Port**: 8080
- **Deploy Directory**: /opt/petclinic
- **Service Name**: petclinic
- **Log Location**: Check with `sudo journalctl -u petclinic`

## Screenshot Evidence

See `production-server-deployed.png` for proof of deployment showing the modified welcome message.

# Verification Script for Jenkins Auto-Deploy

## Quick Verification Steps

### Step 1: Check Current Deployment

```bash
# Access production server
curl http://localhost:9090

# Look for: "Deployed via Jenkins + Ansible CI/CD Pipeline"
```

### Step 2: Make a Code Change

Edit the welcome message with a timestamp:

```bash
cd spring-petclinic
nano src/main/resources/templates/welcome.html
```

Change line to:
```html
<p style="color: #28a745; font-weight: bold;">Deployed via Jenkins + Ansible CI/CD Pipeline - Updated on Dec 3, 2025 at 3:45 PM</p>
```

### Step 3: Commit and Push

```bash
git add src/main/resources/templates/welcome.html
git commit -m "Test auto-deploy with timestamp update"
git push origin main
```

### Step 4: Monitor Jenkins

1. Open Jenkins: http://localhost:8082/jenkins
2. Watch for automatic build trigger (polls every minute)
3. Observe all stages complete:
   - ✓ Checkout
   - ✓ Build (Java 25)
   - ✓ Test (Java 25)
   - ✓ SonarQube Analysis
   - ✓ Quality Gate
   - ✓ Package
   - ✓ Archive
   - ✓ OWASP ZAP Scan
   - ✓ Publish ZAP Report
   - ✓ **Deploy to Production** ← New stage!

### Step 5: Verify Updated Content

After build completes (5-10 minutes):

```bash
# Check production server
curl http://localhost:9090 | grep "Updated on"

# Should show your new timestamp message
```

Or open browser to: http://localhost:9090

### Step 6: Take Screenshots

Take screenshots showing:

1. **Jenkins Pipeline Success**
   - All stages green including "Deploy to Production"
   - Build triggered automatically from Git push

2. **Production Server Welcome Page**
   - Shows updated message with your timestamp
   - Proves deployment happened automatically

3. **Jenkins Console Output**
   - Shows Ansible playbook execution
   - Shows successful deployment messages

## Expected Results

✅ Jenkins detects Git push within 1 minute
✅ Build runs automatically without manual trigger
✅ All test stages pass
✅ Ansible deployment stage executes
✅ Application deployed to production
✅ Updated message visible on production server
✅ Zero manual intervention required

## Verification Checklist

- [ ] Initial deployment shows base message
- [ ] Code change committed and pushed
- [ ] Jenkins build triggered automatically
- [ ] Build completes all stages successfully
- [ ] "Deploy to Production" stage completes
- [ ] Production server shows NEW message
- [ ] No manual deployment steps needed
- [ ] Screenshots captured for evidence

## Evidence to Collect

1. Screenshot: Jenkins pipeline with all green stages
2. Screenshot: Production welcome page with updated message
3. Git commit hash showing the change
4. Jenkins build number that deployed it
5. Timestamp proving automatic trigger

## Troubleshooting

**Jenkins doesn't trigger automatically?**
- Check SCM polling is configured (every minute: `* * * * *`)
- Verify Git repository URL is correct in Jenkins

**Deployment stage fails?**
- Check Ansible is installed in Jenkins container
- Verify SSH access to production server
- Check JAR file exists in target directory

**Old content still showing?**
- Hard refresh browser (Cmd+Shift+R on Mac)
- Check application logs on production server
- Verify deployment actually ran in Jenkins logs

**Can't see deployment stage?**
- Verify Jenkinsfile has "Deploy to Production" stage
- Check Jenkins loaded latest Jenkinsfile from Git
- Restart Jenkins if needed: `docker compose restart jenkins`