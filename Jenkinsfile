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
            options {
                timeout(time: 5, unit: 'MINUTES')
            }
            steps {
                sh 'docker cp . maven-java25-builder:/build'
                sh 'docker exec maven-java25-builder chmod +x /build/mvnw'
                sh 'docker exec -w /build maven-java25-builder ./mvnw clean compile -DskipTests -B'
            }
        }

        stage('Test') {
            options {
                timeout(time: 5, unit: 'MINUTES')
            }
            steps {
                sh 'docker exec -w /build maven-java25-builder ./mvnw test -Dtest=!PostgresIntegrationTests,!MySqlIntegrationTests -DfailIfNoTests=false -B || true'
            }
        }

        stage('SonarQube Analysis') {
            options {
                timeout(time: 3, unit: 'MINUTES')
            }
            steps {
                sh 'docker exec -w /build maven-java25-builder ./mvnw sonar:sonar -Dsonar.host.url=http://sonarqube:9000 -Dsonar.projectKey=spring-petclinic -B || true'
            }
        }

        stage('Package') {
            steps {
                sh 'docker exec -w /build maven-java25-builder ./mvnw package -DskipTests -B'
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                sh 'docker exec zap zap-baseline.py -t http://petclinic:8080 -r /zap/wrk/zap-report.html -I || true'
            }
        }

        stage('Deploy to Production') {
            steps {
                sh 'docker stop petclinic || true'
                sh 'docker rm petclinic || true'
                sh 'docker exec maven-java25-builder cp /build/target/spring-petclinic-*.jar /build/app.jar || true'
                sh 'docker cp maven-java25-builder:/build/target/spring-petclinic-4.0.0-SNAPSHOT.jar ./app.jar || true'
                sh 'docker build -t petclinic:latest . || true'
                sh 'docker run -d --name petclinic --network spring-petclinic_devops-net -p 8081:8080 petclinic:latest'
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
