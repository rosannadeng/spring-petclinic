#!/bin/bash

cd "$(dirname "$0")/.."

echo "Starting DevSecOps Pipeline Demo..."
echo ""

echo "[1/9] Opening app (BEFORE state)..."
open -na "Google Chrome" --args --new-window "http://localhost:8081"
sleep 3

echo "[2/9] Making code change..."
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
for file in src/main/resources/messages/messages*.properties; do
    sed -i '' "s/deploymentInfo=.*/deploymentInfo=Deployed at ${TIMESTAMP}/" "$file" 2>/dev/null
done
echo "Changed to: Deployed at ${TIMESTAMP}"

echo "[3/9] Building application..."
docker run --rm -v "$(pwd)":/app -w /app maven-java25:latest ./mvnw package -DskipTests 2>&1 | grep -E "BUILD|Compiling|Building" | tail -5

echo "[4/9] Building Docker image..."
docker build -t petclinic:latest . >/dev/null 2>&1

echo "[5/9] Deploying new version..."
docker stop petclinic 2>/dev/null
docker rm petclinic 2>/dev/null
docker run -d --name petclinic --network spring-petclinic_devops-net -p 8081:8080 petclinic:latest >/dev/null
echo "Waiting 20 seconds for app to start..."
sleep 20

echo "[6/9] Opening dashboards..."
open -na "Google Chrome" --args --new-window "http://localhost:8081" "http://localhost:8082/jenkins" "http://localhost:9000" "http://localhost:9090/targets" "http://localhost:3030"
sleep 3

echo "[7/9] Pushing to Git..."
git add . >/dev/null 2>&1
git commit -m "Deploy: ${TIMESTAMP}" >/dev/null 2>&1
git push origin main >/dev/null 2>&1
git push origin main:ansible-deployment >/dev/null 2>&1

echo "[8/9] Opening Jenkins pipeline..."
open -na "Google Chrome" --args --new-window "http://localhost:8082/jenkins/blue/organizations/jenkins/petclinic-pipeline/activity"

echo ""
echo "[9/9] Demo complete!"
echo "App now shows: Deployed at ${TIMESTAMP}"
