pipeline {
    agent any

    options {
        skipDefaultCheckout()
    }

    environment {
        DOCKER_NETWORK = "spring-petclinic_devops-net"
        SONAR_HOST = "http://sonarqube:9000"

        SONAR_TOKEN = credentials('SONAR_TOKEN')  
    }

    stages {

        stage("Checkout") {
            steps {
                checkout scm
                sh "ls -la"
            }
        }

        stage("Build") {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "-u root --network ${DOCKER_NETWORK}"
                }
            }
            steps {
                sh "./mvnw clean compile -DskipTests"
            }
        }

        stage("Test") {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "-u root --network ${DOCKER_NETWORK}"
                }
            }
            steps {
                sh "./mvnw test -Dtest=\"!PostgresIntegrationTests\""
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage("SonarQube Analysis") {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "-u root --network ${DOCKER_NETWORK}"
                }
            }
            steps {
                sh """
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v ${WORKSPACE}:/app \
                        -w /app \
                        maven-java25:latest \
                        ./mvnw sonar:sonar \
                        -Dsonar.host.url=${SONAR_HOST} \
                        -Dsonar.login=${SONAR_TOKEN} \
                        -Dsonar.projectKey=spring-petclinic \
                        -Dsonar.projectName=spring-petclinic
                """
            }
        }

        stage("Package") {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "-u root --network ${DOCKER_NETWORK}"
                }
            }
            steps {
                sh "./mvnw package -DskipTests"
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage("Deploy") {
            steps {
                sh """
                docker stop petclinic || true
                docker rm petclinic || true

                docker build -t petclinic:latest -f Dockerfile .

                docker run -d \
                    --name petclinic \
                    --network ${DOCKER_NETWORK} \
                    -p 8081:8080 \
                    petclinic:latest
                """
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
