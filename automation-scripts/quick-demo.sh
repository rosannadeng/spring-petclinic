#!/bin/bash

cd "$(dirname "$0")/.."

echo "Quick Demo"
echo ""

echo "Opening dashboards..."
open -na "Google Chrome" --args --new-window \
    "http://localhost:8081" \
    "http://localhost:8082/jenkins" \
    "http://localhost:9000" \
    "http://localhost:9090/targets" \
    "http://localhost:3030"
sleep 2

TIMESTAMP=$(date +"%H:%M:%S")
for file in src/main/resources/messages/messages*.properties; do
    sed -i '' "s/deploymentInfo=.*/deploymentInfo=Live Demo ${TIMESTAMP}/" "$file" 2>/dev/null
done

echo "Building..."
docker run --rm -v "$(pwd)":/app -w /app maven-java25:latest ./mvnw package -DskipTests -q 2>&1 | tail -1

echo "Deploying..."
docker stop petclinic 2>/dev/null; docker rm petclinic 2>/dev/null
docker build -t petclinic:latest . >/dev/null 2>&1
docker run -d --name petclinic --network spring-petclinic_devops-net -p 8081:8080 petclinic:latest >/dev/null
sleep 15

git add . && git commit -m "Demo ${TIMESTAMP}" && git push origin main 2>/dev/null

echo "Opening results..."
open -na "Google Chrome" --args --new-window \
    "http://localhost:8081" \
    "http://localhost:8082/jenkins/blue/organizations/jenkins/petclinic-pipeline/activity"

echo ""
echo "Done!"
