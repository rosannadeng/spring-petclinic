#!/bin/bash

cd "$(dirname "$0")/.."

echo "Starting DevSecOps Pipeline Demo..."
echo ""

echo "[1/8] Stopping existing containers..."
docker stop petclinic 2>/dev/null
docker rm petclinic 2>/dev/null
docker compose down 2>/dev/null

echo "[2/8] Making code change..."
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
for file in src/main/resources/messages/messages*.properties; do
    sed -i '' "s/deploymentInfo=.*/deploymentInfo=Deployed at ${TIMESTAMP}/" "$file" 2>/dev/null
done
echo "Changed to: Deployed at ${TIMESTAMP}"

echo "[3/8] Building application..."
docker run --rm -v "$(pwd)":/app -w /app maven-java25:latest ./mvnw package -DskipTests 2>&1 | grep -E "BUILD|Compiling|Building" | tail -5

echo "[4/8] Building Docker image..."
docker build -t petclinic:latest . >/dev/null 2>&1

echo "[5/8] Starting all services..."
docker compose up -d
echo "Waiting 25 seconds..."
sleep 25

echo "[6/8] Opening dashboards..."
open -na "Google Chrome" --args --new-window "http://localhost:8081" "http://localhost:8082/jenkins" "http://localhost:9000" "http://localhost:9090/targets" "http://localhost:3030"
sleep 3

echo "[7/8] Pushing to Git..."
git add . >/dev/null 2>&1
git commit -m "Deploy: ${TIMESTAMP}" >/dev/null 2>&1
git push origin main >/dev/null 2>&1

echo "[8/8] Opening Jenkins pipeline..."
open -na "Google Chrome" --args --new-window "http://localhost:8082/jenkins/blue/organizations/jenkins/petclinic-pipeline/activity"

echo ""
echo "Demo complete!"
