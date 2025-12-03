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

