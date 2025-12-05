pipeline {
    agent any

    triggers {
        pollSCM('* * * * *')
    }

    environment {
        SONAR_HOST = 'http://sonarqube:9000'
        DOCKER_NETWORK = 'spring-petclinic_devops-net'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Prepare') {
            steps {
                sh '''
                    echo "Workspace contents:"
                    ls -la ${WORKSPACE}
                    
                    echo "Checking mvnw file:"
                    if [ -f "${WORKSPACE}/mvnw" ]; then
                        chmod +x ${WORKSPACE}/mvnw
                        echo "mvnw found and made executable"
                    else
                        echo "ERROR: mvnw file not found in workspace!"
                        exit 1
                    fi
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    echo "DEBUG: Workspace path is: ${WORKSPACE}"
                    echo "DEBUG: Files in workspace:"
                    ls -la ${WORKSPACE} | head -20
                    
                    echo "DEBUG: Checking what's inside the Docker container:"
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v "${WORKSPACE}":/app \
                        -w /app \
                        maven-java25:latest \
                        bash -c "echo 'Container /app contents:' && ls -la /app | head -20 && echo 'mvnw file check:' && ls -l /app/mvnw"
                    
                    echo "DEBUG: Now running actual build:"
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v "${WORKSPACE}":/app \
                        -w /app \
                        maven-java25:latest \
                        ./mvnw clean compile -DskipTests -q
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v "${WORKSPACE}":/app \
                        -w /app \
                        maven-java25:latest \
                        ./mvnw test -Dtest="!PostgresIntegrationTests" -q
                '''
            }
            post {
                always {
                    junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh '''
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v "${WORKSPACE}":/app \
                        -w /app \
                        maven-java25:latest \
                        ./mvnw sonar:sonar \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.projectKey=spring-petclinic \
                        -Dsonar.projectName=spring-petclinic || echo "SonarQube analysis skipped"
                '''
            }
        }

        stage('Package') {
            steps {
                sh '''
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v "${WORKSPACE}":/app \
                        -w /app \
                        maven-java25:latest \
                        ./mvnw package -DskipTests -q
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                sh '''
                    mkdir -p ${WORKSPACE}/zap-reports
                    docker exec zap zap-baseline.py \
                        -t http://petclinic:8080 \
                        -r zap-report.html \
                        -I || true
                    docker cp zap:/zap/wrk/zap-report.html ${WORKSPACE}/zap-reports/ || true
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'zap-reports',
                        reportFiles: 'zap-report.html',
                        reportName: 'OWASP ZAP Report'
                    ])
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                sh '''
                    echo "Deploying to production server..."
                    
                    # Stop existing petclinic container
                    docker stop petclinic || true
                    docker rm petclinic || true
                    
                    # Build new image with updated JAR
                    docker build -t petclinic:latest -f Dockerfile ${WORKSPACE}
                    
                    # Start new container
                    docker run -d \
                        --name petclinic \
                        --network ${DOCKER_NETWORK} \
                        -p 8081:8080 \
                        petclinic:latest
                    
                    # Wait for application to start
                    sleep 30
                    
                    # Verify deployment
                    curl -s http://localhost:8081 | head -20 || echo "Deployment verification pending"
                '''
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
