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

