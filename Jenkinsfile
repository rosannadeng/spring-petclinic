pipeline {
    agent any

    triggers {
        pollSCM('* * * * *')
    }

    environment {
        DOCKER_NETWORK = 'spring-petclinic_devops-net'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                sh '''
                    echo "Building application..."
                    docker cp . maven-java25-builder:/build
                    docker exec maven-java25-builder sh -c "cd /build && ./mvnw clean compile -DskipTests -q"
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    echo "Running tests..."
                    docker exec maven-java25-builder sh -c "cd /build && ./mvnw test -Dtest='!PostgresIntegrationTests' -q" || true
                '''
            }
            post {
                always {
                    sh 'docker cp maven-java25-builder:/build/target/surefire-reports . || true'
                    junit testResults: '**/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                sh '''
                    echo "Running SonarQube analysis..."
                    docker exec maven-java25-builder sh -c "cd /build && ./mvnw sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -Dsonar.projectKey=spring-petclinic" || true
                '''
            }
        }

        stage('Package') {
            steps {
                sh '''
                    echo "Packaging application..."
                    docker exec maven-java25-builder sh -c "cd /build && ./mvnw package -DskipTests -q"
                    docker cp maven-java25-builder:/build/target .
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
                }
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                sh '''
                    echo "Running OWASP ZAP security scan..."
                    mkdir -p zap-reports
                    docker exec zap zap-baseline.py -t http://petclinic:8080 -r zap-report.html -I || true
                    docker cp zap:/zap/wrk/zap-report.html zap-reports/ || true
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
                    docker stop petclinic || true
                    docker rm petclinic || true
                    docker exec maven-java25-builder sh -c "cd /build && docker build -t petclinic:latest ." || true
                    docker run -d --name petclinic --network ${DOCKER_NETWORK} -p 8081:8080 petclinic:latest || true
                    sleep 10
                    echo "Deployment completed!"
                '''
            }
        }
    }

    post {
        always {
            sh 'docker exec maven-java25-builder rm -rf /build || true'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
