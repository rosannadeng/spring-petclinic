#!/bin/bash

cd "$(dirname "$0")/.."

echo "Starting DevSecOps Pipeline Demo..."
echo ""

echo "[1/7] Starting Docker services..."
docker compose down 2>/dev/null
docker compose up -d
echo "Waiting 20 seconds for services..."
sleep 20

echo "[2/7] Opening all dashboards..."
open -na "Google Chrome" --args --new-window \
    "http://localhost:8081" \
    "http://localhost:8082/jenkins" \
    "http://localhost:9000" \
    "http://localhost:9090/targets" \
    "http://localhost:3030"
sleep 3

echo "[3/7] Making code change..."
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
for file in src/main/resources/messages/messages*.properties; do
    sed -i '' "s/deploymentInfo=.*/deploymentInfo=Deployed at ${TIMESTAMP}/" "$file" 2>/dev/null
done

echo "[4/7] Building..."
docker run --rm -v "$(pwd)":/app -w /app maven-java25:latest ./mvnw package -DskipTests -q 2>&1 | tail -1

echo "[5/7] Deploying to container..."
docker stop petclinic 2>/dev/null; docker rm petclinic 2>/dev/null
docker build -t petclinic:latest . >/dev/null 2>&1
docker run -d --name petclinic --network spring-petclinic_devops-net -p 8081:8080 petclinic:latest >/dev/null
echo "Waiting 15 seconds for app..."
sleep 15

echo "[6/7] Pushing to Git..."
git add . >/dev/null 2>&1
git commit -m "Deploy: ${TIMESTAMP}" >/dev/null 2>&1
git push origin main >/dev/null 2>&1

echo "[7/7] Opening updated app and Jenkins..."
open -na "Google Chrome" --args --new-window \
    "http://localhost:8081" \
    "http://localhost:8082/jenkins/blue/organizations/jenkins/petclinic-pipeline/activity"

echo ""
echo "Demo complete!"
