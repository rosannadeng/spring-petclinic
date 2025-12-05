#!/bin/bash

cd "$(dirname "$0")/.."

echo "Quick Demo - Services already running"
echo ""

open "http://localhost:8081"
sleep 1
open "http://localhost:8082/jenkins"
sleep 1
open "http://localhost:9000"
sleep 1
open "http://localhost:9090"
sleep 1
open "http://localhost:3030"
sleep 1

TIMESTAMP=$(date +"%H:%M:%S")
for file in src/main/resources/messages/messages*.properties; do
    sed -i '' "s/deploymentInfo=.*/deploymentInfo=Live Demo ${TIMESTAMP}/" "$file" 2>/dev/null
done

docker run --rm -v "$(pwd)":/app -w /app maven-java25:latest ./mvnw package -DskipTests -q 2>&1 | tail -1
docker stop petclinic 2>/dev/null; docker rm petclinic 2>/dev/null
docker build -t petclinic:latest . >/dev/null 2>&1
docker run -d --name petclinic --network spring-petclinic_devops-net -p 8081:8080 petclinic:latest >/dev/null
sleep 15

git add . && git commit -m "Demo ${TIMESTAMP}" && git push origin main 2>/dev/null

open "http://localhost:8081"
open "http://localhost:8082/jenkins/blue/organizations/jenkins/petclinic-pipeline/activity"

echo "Done!"
