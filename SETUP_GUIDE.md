# Complete CI/CD Pipeline Setup Guide for Spring PetClinic

**A step-by-step guide for absolute beginners** - Every command you need to run is included!

## 📋 What You'll Build

A complete DevOps pipeline with:
- ✅ Jenkins (CI/CD automation)
- ✅ SonarQube (Code quality analysis)
- ✅ OWASP ZAP (Security scanning)
- ✅ Prometheus (Metrics collection)
- ✅ Grafana (Monitoring dashboards)

## 🖥️ Prerequisites

### Required Software

1. **Docker Desktop**
   - Download: https://www.docker.com/products/docker-desktop
   - Install and start Docker Desktop
   - Verify installation:
     ```bash
     docker --version
     docker compose version
     ```
   - You should see version numbers (e.g., Docker version 24.x.x)

2. **Git**
   - Download: https://git-scm.com/downloads
   - Verify installation:
     ```bash
     git --version
     ```

3. **System Requirements**
   - RAM: At least 8GB (16GB recommended)
   - Disk: At least 20GB free space
   - OS: Windows 10/11, macOS, or Linux

## 🚀 Step-by-Step Setup

### Step 1: Get the Code

Open your terminal (Command Prompt on Windows, Terminal on Mac/Linux) and run:

```bash
# Navigate to where you want to store the project
cd ~/Documents

# Clone the repository (replace with your fork URL)
git clone https://github.com/YOUR_USERNAME/spring-petclinic.git

# Enter the project directory
cd spring-petclinic

# Verify you're in the right place
ls -la
```

**Expected output:** You should see files like `Jenkinsfile`, `docker-compose.yml`, `pom.xml`, etc.

---

### Step 2: Build Custom Docker Images

We need to build two custom Docker images before starting services.

#### 2.1 Build Jenkins Image (with Docker CLI and plugins)

```bash
# Build Jenkins image from Dockerfile.jenkins
docker compose build jenkins

# This takes 5-10 minutes
# You'll see output like:
# [+] Building 234.5s (12/12) FINISHED
```

**What this does:** Creates a Jenkins image with:
- Docker CLI installed (to run Docker commands inside Jenkins)
- All required plugins pre-installed (SonarQube, Blue Ocean, HTML Publisher, etc.)

#### 2.2 Build Maven-Java25 Image

```bash
# Build Maven with Java 25 image
docker compose build maven-java25

# This takes 2-3 minutes
```

**What this does:** Creates a Maven build environment with Java 25 (required by this project).

#### 2.3 Verify Images Were Built

```bash
# Check that images were created
docker images | grep -E "jenkins|maven-java25"
```

**Expected output:**
```
spring-petclinic-jenkins        latest    abc123def456   2 minutes ago   1.2GB
maven-java25                    latest    def789ghi012   1 minute ago    850MB
```

---

### Step 3: Start All Services

```bash
# Start all services in detached mode (background)
docker compose up -d

# Wait for services to start (this takes 2-3 minutes)
```

**What this does:** Starts containers for Jenkins, SonarQube, PostgreSQL, Prometheus, and Grafana.

#### 3.1 Verify All Services Are Running

```bash
# Check running containers
docker compose ps

# Or use:
docker ps
```

**Expected output:** You should see 5+ containers running:
```
NAME                STATUS              PORTS
jenkins             Up 2 minutes        0.0.0.0:8082->8080/tcp
sonarqube           Up 2 minutes        0.0.0.0:9000->9000/tcp
postgres            Up 2 minutes        0.0.0.0:5432->5432/tcp
prometheus          Up 2 minutes        0.0.0.0:9090->9090/tcp
grafana             Up 2 minutes        0.0.0.0:3000->3000/tcp
```

#### 3.2 Check Service Logs (Optional)

```bash
# View Jenkins logs
docker logs jenkins

# View SonarQube logs
docker logs sonarqube

# Follow logs in real-time (Ctrl+C to exit)
docker logs -f jenkins
```

---

### Step 4: Configure SonarQube

#### 4.1 Access SonarQube Web Interface

1. Open your web browser
2. Go to: **http://localhost:9000**
3. Wait for SonarQube to fully start (you'll see the login page)

#### 4.2 Initial Login

- **Username:** `admin`
- **Password:** `admin`
- Click **"Log in"**

#### 4.3 Change Password (Required)

1. You'll be prompted: "Please change the default password"
2. Enter:
   - **Old password:** `admin`
   - **New password:** (choose a strong password)
   - **Confirm password:** (same password)
3. Click **"Update"**
4. **⚠️ IMPORTANT:** Write down your new password!

#### 4.4 Generate Authentication Token

1. Click on your profile icon (top right corner, letter 'A')
2. Select **"My Account"**
3. Click on the **"Security"** tab
4. Under **"Generate Tokens"**:
   - **Name:** `jenkins`
   - **Type:** Select **"Global Analysis Token"**
   - **Expires in:** Select **"No expiration"**
5. Click **"Generate"**
6. **⚠️ CRITICAL:** You'll see a token like `squ_1234567890abcdefghijklmnop`
7. **Copy this token immediately** - it won't be shown again!
8. Save it in a text file temporarily

---

### Step 5: Create Environment File with Token

#### 5.1 Create `.env` File

In your terminal, run:

```bash
# Make sure you're in the project directory
cd ~/Documents/spring-petclinic

# Create .env file with your token
cat > .env << 'EOF'
SONAR_AUTH_TOKEN=PASTE_YOUR_TOKEN_HERE
EOF
```

**Replace `PASTE_YOUR_TOKEN_HERE` with your actual token from Step 4.4**

Example:
```bash
cat > .env << 'EOF'
SONAR_AUTH_TOKEN=squ_1234567890abcdefghijklmnop
EOF
```

#### 5.2 Verify `.env` File

```bash
# Check the file was created
cat .env

# You should see:
# SONAR_AUTH_TOKEN=squ_your_actual_token
```

#### 5.3 Restart Services to Load Token

```bash
# Stop all services
docker compose down

# Start services again (they'll read the .env file)
docker compose up -d

# Wait 2-3 minutes for services to restart
```

#### 5.4 Verify Token Was Loaded

```bash
# Check if Jenkins has the environment variable
docker exec jenkins env | grep SONAR_AUTH_TOKEN

# You should see:
# SONAR_AUTH_TOKEN=squ_your_actual_token
```

---

### Step 6: Configure Jenkins

#### 6.1 Access Jenkins Web Interface

1. Open your web browser
2. Go to: **http://localhost:8082/jenkins**
3. You'll see "Unlock Jenkins" page

#### 6.2 Get Initial Admin Password

In your terminal, run:

```bash
# Get the initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

**Expected output:** A long string like `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

1. Copy this password
2. Paste it into the Jenkins "Administrator password" field
3. Click **"Continue"**

#### 6.3 Install Plugins

1. Select **"Install suggested plugins"**
2. Wait for plugins to install (this takes 5-10 minutes)
3. You'll see a progress bar with plugin names

#### 6.4 Create First Admin User

Fill in the form:
- **Username:** (your choice, e.g., `admin`)
- **Password:** (choose a strong password)
- **Confirm password:** (same password)
- **Full name:** (your name)
- **Email address:** (your email)

Click **"Save and Continue"**

#### 6.5 Instance Configuration

1. **Jenkins URL:** Keep default `http://localhost:8082/jenkins/`
2. Click **"Save and Finish"**
3. Click **"Start using Jenkins"**

#### 6.6 Configure SonarQube Server in Jenkins

**Option A: Verify Automatic Configuration (Recommended)**

1. Go to **"Manage Jenkins"** (left sidebar)
2. Click **"Configure System"**
3. Scroll down to **"SonarQube servers"** section
4. You should see:
   - Name: `SonarQubeServer`
   - Server URL: `http://sonarqube:9000`
   - Server authentication token: `sonar-token`

If you see this, **skip to Step 7**. If not, continue with Option B.

**Option B: Manual Configuration**

1. Go to **"Manage Jenkins"** → **"Configure System"**
2. Scroll to **"SonarQube servers"**
3. Click **"Add SonarQube"**
4. Fill in:
   - **Name:** `SonarQubeServer` (must be exactly this!)
   - **Server URL:** `http://sonarqube:9000`
   - **Server authentication token:** Click **"Add"** → **"Jenkins"**
5. In the popup:
   - **Kind:** Select **"Secret text"**
   - **Scope:** Global
   - **Secret:** Paste your SonarQube token from Step 4.4
   - **ID:** `sonar-token`
   - **Description:** `SonarQube Authentication Token`
   - Click **"Add"**
6. Select `sonar-token` from the dropdown
7. Click **"Save"** at the bottom

#### 6.7 Verify Tools Configuration

1. Go to **"Manage Jenkins"** → **"Global Tool Configuration"**
2. Verify you see:
   - **Maven installations:** `Maven 3.9.5`
   - **JDK installations:** `JDK 25`

These are auto-configured by `jenkins.yaml`.

---

### Step 7: Create Jenkins Pipeline

#### 7.1 Create New Pipeline Job

1. From Jenkins homepage, click **"New Item"** (left sidebar)
2. Enter item name: `spring-petclinic-pipeline`
3. Select **"Pipeline"**
4. Click **"OK"**

#### 7.2 Configure Pipeline Source

Scroll down to the **"Pipeline"** section:

1. **Definition:** Select **"Pipeline script from SCM"**
2. **SCM:** Select **"Git"**
3. **Repository URL:** Enter your repository URL
   - Example: `https://github.com/YOUR_USERNAME/spring-petclinic.git`
4. **Credentials:** Leave as **"- none -"** (for public repos)
5. **Branch Specifier:** `*/main` (or `*/master` if your default branch is master)
6. **Script Path:** `Jenkinsfile`
7. Click **"Save"**

---

### Step 8: Run Your First Build

#### 8.1 Trigger Build

1. Click **"Build Now"** (left sidebar)
2. You'll see a build appear in **"Build History"**
3. Click on the build number (e.g., **#1**)

#### 8.2 Watch Build Progress

**Option A: Classic View**
- Click on the build number
- Click **"Console Output"** to see real-time logs

**Option B: Blue Ocean (Recommended)**
- Click **"Open Blue Ocean"** (left sidebar)
- You'll see a visual pipeline with stages

#### 8.3 Build Stages

The pipeline will execute these stages (takes 15-20 minutes on first run):

1. **Checkout** - Downloads code from Git
2. **Build (Java 25)** - Compiles the application
3. **Test (Java 25)** - Runs unit tests
4. **SonarQube Analysis** - Analyzes code quality
5. **Quality Gate** - Waits for SonarQube results
6. **Checkstyle** - Checks code style
7. **Package** - Creates JAR file
8. **Archive** - Saves artifacts
9. **OWASP ZAP Scan** - Security scanning
10. **Publish ZAP Report** - Publishes security report

#### 8.4 Monitor Build

```bash
# In another terminal, watch Jenkins logs
docker logs -f jenkins

# Watch SonarQube logs
docker logs -f sonarqube
```

---

### Step 9: View Results

#### 9.1 Check Build Status

In Jenkins:
- ✅ **Green checkmark** = Build succeeded
- ❌ **Red X** = Build failed
- ⚠️ **Yellow warning** = Unstable (tests failed but build succeeded)

#### 9.2 View SonarQube Analysis

1. Go to **http://localhost:9000**
2. Click on **"spring-petclinic"** project
3. View:
   - **Bugs:** Code issues that could cause errors
   - **Vulnerabilities:** Security issues
   - **Code Smells:** Maintainability issues
   - **Coverage:** Test coverage percentage
   - **Duplications:** Duplicate code

#### 9.3 View OWASP ZAP Security Report

1. In Jenkins, click on your build (e.g., **#1**)
2. Click **"OWASP ZAP Security Report"** (left sidebar)
3. Review security findings:
   - **Warnings:** Potential security issues
   - **Passed:** Security checks that passed

#### 9.4 View Test Results

1. In Jenkins build page
2. Click **"Test Result"** (left sidebar)
3. See:
   - Total tests
   - Passed tests
   - Failed tests
   - Test duration

#### 9.5 View Code Coverage

1. In Jenkins build page
2. Click **"Coverage Report"** (left sidebar)
3. See JaCoCo coverage report with line/branch coverage

---

## 🔧 Common Commands Reference

### Docker Commands

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a specific service
docker compose restart jenkins

# View logs
docker logs jenkins
docker logs sonarqube

# Follow logs in real-time
docker logs -f jenkins

# Check running containers
docker compose ps
docker ps

# Stop and remove everything (including volumes)
docker compose down -v

# Rebuild images
docker compose build --no-cache jenkins
docker compose build --no-cache maven-java25

# Clean up Docker system
docker system prune -a --volumes -f
```

### Jenkins Commands

```bash
# Get initial admin password
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Check environment variables
docker exec jenkins env | grep SONAR

# Restart Jenkins
docker compose restart jenkins

# View Jenkins home directory
docker exec jenkins ls -la /var/jenkins_home
```

### SonarQube Commands

```bash
# Check SonarQube logs
docker logs sonarqube

# Restart SonarQube
docker compose restart sonarqube

# Check SonarQube is responding
curl http://localhost:9000/api/system/status
```

---

## 🐛 Troubleshooting Guide

### Problem 1: "Port already in use"

**Error:** `Bind for 0.0.0.0:8082 failed: port is already allocated`

**Solution:**
```bash
# Find what's using the port
lsof -i :8082  # On Mac/Linux
netstat -ano | findstr :8082  # On Windows

# Kill the process or change port in docker-compose.yml
```

### Problem 2: Jenkins won't start

**Symptoms:** Jenkins container keeps restarting

**Solution:**
```bash
# Check logs for errors
docker logs jenkins

# Common fix: Remove and recreate
docker compose down
docker volume rm spring-petclinic_jenkins_home
docker compose up -d
```

### Problem 3: SonarQube "Not authorized" error

**Symptoms:** Build fails at SonarQube Analysis stage with authentication error

**Solution:**
```bash
# 1. Verify .env file exists and has correct token
cat .env

# 2. Restart services to reload environment
docker compose down
docker compose up -d

# 3. Verify token is loaded in Jenkins
docker exec jenkins env | grep SONAR_AUTH_TOKEN

# 4. If still failing, manually add credential in Jenkins UI
```

### Problem 4: Out of disk space

**Symptoms:** Build fails with "no space left on device"

**Solution:**
```bash
# Clean up Docker
docker system prune -a --volumes -f

# Check disk space
df -h  # Mac/Linux
```

### Problem 5: Build is very slow

**Symptoms:** First build takes 30+ minutes

**Solution:**
- This is normal for first build (downloading dependencies)
- Subsequent builds will be much faster (5-10 minutes)
- Increase Docker memory: Docker Desktop → Settings → Resources → Memory (8GB+)

### Problem 6: Can't access Jenkins/SonarQube

**Symptoms:** Browser shows "Connection refused"

**Solution:**
```bash
# 1. Check services are running
docker compose ps

# 2. Wait longer (services take 2-3 minutes to start)
docker logs jenkins  # Check if Jenkins is ready

# 3. Restart services
docker compose restart jenkins sonarqube
```

---

## 📊 Understanding the Pipeline

### What Each Stage Does

1. **Checkout**
   - Downloads code from Git repository
   - Duration: ~5 seconds

2. **Build (Java 25)**
   - Compiles Java source code
   - Downloads Maven dependencies (slow on first run)
   - Duration: 2-10 minutes (first run), 30 seconds (subsequent)

3. **Test (Java 25)**
   - Runs JUnit tests
   - Generates test reports
   - Duration: 1-2 minutes

4. **SonarQube Analysis**
   - Analyzes code quality
   - Finds bugs, vulnerabilities, code smells
   - Calculates test coverage
   - Duration: 1-2 minutes

5. **Quality Gate**
   - Waits for SonarQube to finish processing
   - Checks if code meets quality standards
   - Fails build if quality gate fails
   - Duration: 10-30 seconds

6. **Checkstyle**
   - Checks code formatting and style
   - Generates warnings for style violations
   - Duration: 30 seconds

7. **Package**
   - Creates executable JAR file
   - Duration: 30 seconds

8. **Archive**
   - Saves JAR file as Jenkins artifact
   - Duration: 5 seconds

9. **OWASP ZAP Scan**
   - Starts application in Docker
   - Scans for security vulnerabilities
   - Tests for common web vulnerabilities (XSS, SQL injection, etc.)
   - Duration: 2-3 minutes

10. **Publish ZAP Report**
    - Makes security report available in Jenkins
    - Duration: 5 seconds

### Total Build Time

- **First build:** 15-20 minutes (downloading dependencies)
- **Subsequent builds:** 5-10 minutes

---

## 🔐 Security Best Practices

### 1. Protect Your Tokens

```bash
# Never commit .env file to Git
echo ".env" >> .gitignore

# Verify .env is ignored
git status  # Should not show .env
```

### 2. Use Strong Passwords

- Jenkins admin: Use password manager
- SonarQube admin: Change from default immediately
- Use different passwords for each service

### 3. Limit Access

- Don't expose Jenkins/SonarQube to internet without authentication
- Use firewall rules if deploying to server
- Consider using HTTPS in production

### 4. Regular Updates

```bash
# Update Docker images regularly
docker compose pull
docker compose up -d
```

---

## 📚 Additional Resources

### Access URLs

- **Jenkins:** http://localhost:8082/jenkins
- **SonarQube:** http://localhost:9000
- **Prometheus:** http://localhost:9090
- **Grafana:** http://localhost:3000
- **Application (when running):** http://localhost:8080

### Default Credentials

| Service | Username | Password |
|---------|----------|----------|
| SonarQube | admin | admin (change on first login) |
| Grafana | admin | admin |
| Jenkins | (you create) | (you create) |

### Useful Documentation

- Jenkins: https://www.jenkins.io/doc/
- SonarQube: https://docs.sonarqube.org/
- OWASP ZAP: https://www.zaproxy.org/docs/
- Docker Compose: https://docs.docker.com/compose/

---

## 🎯 Next Steps

After successful setup:

### 1. Set Up Automatic Builds

Configure GitHub webhook to trigger builds on push:
1. In GitHub: Settings → Webhooks → Add webhook
2. Payload URL: `http://YOUR_JENKINS_URL/github-webhook/`
3. Content type: `application/json`
4. Events: Push events

### 2. Configure Grafana Dashboards

1. Go to http://localhost:3000
2. Login: admin/admin
3. Add Prometheus data source
4. Import Jenkins dashboard

### 3. Fix Code Quality Issues

1. Review SonarQube findings
2. Fix bugs and vulnerabilities
3. Improve test coverage
4. Reduce code smells

### 4. Address Security Findings

1. Review OWASP ZAP report
2. Add security headers
3. Fix CSRF vulnerabilities
4. Implement proper authentication

---

## ✅ Verification Checklist

Use this checklist to verify everything is working:

- [ ] Docker Desktop is running
- [ ] All 5+ containers are running (`docker ps`)
- [ ] Jenkins is accessible at http://localhost:8082/jenkins
- [ ] SonarQube is accessible at http://localhost:9000
- [ ] `.env` file exists with SonarQube token
- [ ] Jenkins has SonarQube server configured
- [ ] Pipeline job is created
- [ ] First build completed successfully
- [ ] SonarQube shows project analysis
- [ ] OWASP ZAP report is visible in Jenkins
- [ ] Test results are visible in Jenkins
- [ ] JAR artifact is archived

---

## 🆘 Getting Help

If you're stuck:

1. **Check logs:**
   ```bash
   docker logs jenkins
   docker logs sonarqube
   ```

2. **Verify services:**
   ```bash
   docker compose ps
   docker ps
   ```

3. **Check this guide's Troubleshooting section**

4. **Common issues:**
   - Wait longer (services need 2-3 minutes to start)
   - Restart services (`docker compose restart`)
   - Check disk space (`df -h`)
   - Verify `.env` file has correct token

---

**Congratulations! 🎉**

You now have a fully functional CI/CD pipeline with:
- ✅ Automated builds and tests
- ✅ Code quality analysis
- ✅ Security scanning
- ✅ Monitoring and metrics

**Happy coding!** 🚀

