pipeline {
    agent any

    options {
        skipDefaultCheckout()
    }

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
                sh "echo 'Checked out project into WORKSPACE = ${WORKSPACE}'"
                sh "ls -la ${WORKSPACE}"
            }
        }

        stage('Prepare mvnw') {
            steps {
                sh '''
                    echo "Fixing mvnw permissions..."
                    cd ${WORKSPACE}

                    ls -la mvnw || echo "mvnw missing!"

                    chmod +x mvnw || true

                    command -v dos2unix && dos2unix mvnw || true

                    echo "mvnw ready."
                '''
            }
        }

        stage('DEBUG') {
            steps {
                sh '''
                    echo "WORKSPACE = ${WORKSPACE}"
                    ls -la ${WORKSPACE}
                '''
            }
        }

        stage('Build') {
            steps {
                sh '''
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v ${WORKSPACE}:/app \
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
                        -v ${WORKSPACE}:/app \
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
                        -v ${WORKSPACE}:/app \
                        -w /app \
                        maven-java25:latest \
                        ./mvnw sonar:sonar \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.projectKey=spring-petclinic \
                        -Dsonar.projectName=spring-petclinic \
                        || echo "Sonar analysis skipped"
                '''
            }
        }

        stage('Package') {
            steps {
                sh '''
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v ${WORKSPACE}:/app \
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

                    docker build -t petclinic:latest -f Dockerfile ${WORKSPACE}

                    docker run -d \
                        --name petclinic \
                        --network ${DOCKER_NETWORK} \
                        -p 8081:8080 \
                        petclinic:latest

                    sleep 30
                    curl -s http://localhost:8081 | head -20 || echo "App not ready yet"
                '''
            }
        }
    }

    post {
        always {
            echo 'skip cleanWs'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
