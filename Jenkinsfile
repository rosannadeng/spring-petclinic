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
                sh 'docker cp . maven-java25-builder:/build'
                sh 'docker exec maven-java25-builder /bin/sh -c "cd /build && chmod +x mvnw && ./mvnw clean compile -DskipTests"'
            }
        }

        stage('Test') {
            steps {
                sh 'docker exec maven-java25-builder /bin/sh -c "cd /build && ./mvnw test -Dtest=!PostgresIntegrationTests" || true'
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
                sh 'docker exec maven-java25-builder /bin/sh -c "cd /build && ./mvnw sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -Dsonar.projectKey=spring-petclinic" || true'
            }
        }

        stage('Package') {
            steps {
                sh 'docker exec maven-java25-builder /bin/sh -c "cd /build && ./mvnw package -DskipTests"'
                sh 'docker cp maven-java25-builder:/build/target .'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true, allowEmptyArchive: true
                }
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                sh 'mkdir -p zap-reports'
                sh 'docker exec zap zap-baseline.py -t http://petclinic:8080 -r zap-report.html -I || true'
                sh 'docker cp zap:/zap/wrk/zap-report.html zap-reports/ || true'
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
                sh 'docker stop petclinic || true'
                sh 'docker rm petclinic || true'
                sh 'docker cp maven-java25-builder:/build/target/spring-petclinic-*.jar ./app.jar'
                sh 'docker build -t petclinic:latest .'
                sh 'docker run -d --name petclinic --network spring-petclinic_devops-net -p 8081:8080 petclinic:latest'
                sh 'sleep 10'
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
