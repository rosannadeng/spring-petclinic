#!/bin/bash

cd "$(dirname "$0")/.."

echo "Starting DevSecOps Pipeline Demo..."
echo ""

echo "[1/8] Starting Docker services..."
docker compose up -d
echo "Waiting 20 seconds for services..."
sleep 20

echo "[2/8] Opening PetClinic (current state)..."
open "http://localhost:8081"
sleep 3

echo "[3/8] Opening Jenkins..."
open "http://localhost:8082/jenkins"
sleep 2

echo "[4/8] Opening SonarQube..."
open "http://localhost:9000"
sleep 2

echo "[5/8] Opening Prometheus..."
open "http://localhost:9090"
sleep 2

echo "[6/8] Opening Grafana..."
open "http://localhost:3030"
sleep 2

echo "[7/8] Making code change and deploying..."
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
for file in src/main/resources/messages/messages*.properties; do
    sed -i '' "s/deploymentInfo=.*/deploymentInfo=Deployed at ${TIMESTAMP}/" "$file" 2>/dev/null
done

docker run --rm -v "$(pwd)":/app -w /app maven-java25:latest ./mvnw package -DskipTests -q 2>&1 | tail -1
docker stop petclinic 2>/dev/null; docker rm petclinic 2>/dev/null
docker build -t petclinic:latest . >/dev/null 2>&1
docker run -d --name petclinic --network spring-petclinic_devops-net -p 8081:8080 petclinic:latest >/dev/null
echo "Waiting 15 seconds for app..."
sleep 15

echo "[8/8] Pushing to Git (triggers Jenkins pipeline)..."
git add . >/dev/null 2>&1
git commit -m "Deploy: ${TIMESTAMP}" >/dev/null 2>&1
git push origin main >/dev/null 2>&1

echo ""
echo "Opening updated application..."
open "http://localhost:8081"
sleep 2

echo "Opening Jenkins Blue Ocean..."
open "http://localhost:8082/jenkins/blue/organizations/jenkins/petclinic-pipeline/activity"

echo ""
echo "Demo complete!"
echo ""
echo "URLs:"
echo "  PetClinic:  http://localhost:8081"
echo "  Jenkins:    http://localhost:8082/jenkins"
echo "  SonarQube:  http://localhost:9000"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana:    http://localhost:3030"
