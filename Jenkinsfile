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
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "--network ${DOCKER_NETWORK}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    chmod +x ./mvnw
                    ./mvnw clean compile -DskipTests -q
                '''
            }
        }

        stage('Test') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "--network ${DOCKER_NETWORK}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    chmod +x ./mvnw
                    ./mvnw test -Dtest="!PostgresIntegrationTests" -q
                '''
            }
        }

        stage('SonarQube Analysis') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "--network ${DOCKER_NETWORK}"
                    reuseNode true
                }
            }
            steps {
                script {
                    withSonarQubeEnv('SonarQubeServer') {
                        sh '''
                            chmod +x ./mvnw
                            ./mvnw sonar:sonar \
                                -Dsonar.projectKey=spring-petclinic \
                                -Dsonar.projectName=spring-petclinic || echo "SonarQube analysis failed, continuing..."
                        '''
                    }
                }
            }
        }

        stage('Package') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "--network ${DOCKER_NETWORK}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    chmod +x ./mvnw
                    ./mvnw package -DskipTests -q
                '''
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        stage('OWASP ZAP Baseline Scan') {
            steps {
                sh '''
                    mkdir -p "${WORKSPACE}/zap-reports"
                    # Run ZAP scan in container with temporary volume
                    docker run --name zap-scan-${BUILD_NUMBER} \
                      --platform linux/amd64 \
                      --network ${DOCKER_NETWORK} \
                      --user root \
                      -v zap-reports-${BUILD_NUMBER}:/zap/wrk \
                      ghcr.io/zaproxy/zaproxy:stable \
                      bash -c "chown -R zap:zap /zap/wrk && su zap -c 'zap-baseline.py -t http://petclinic:8080 -r zap-report.html -w zap-report.md -x zap-report.xml -I'" || true
                    
                    # Copy reports from container to Jenkins workspace
                    docker cp zap-scan-${BUILD_NUMBER}:/zap/wrk/zap-report.html "${WORKSPACE}/zap-reports/" 2>/dev/null || true
                    docker cp zap-scan-${BUILD_NUMBER}:/zap/wrk/zap-report.md "${WORKSPACE}/zap-reports/" 2>/dev/null || true
                    docker cp zap-scan-${BUILD_NUMBER}:/zap/wrk/zap-report.xml "${WORKSPACE}/zap-reports/" 2>/dev/null || true
                    
                    # Cleanup
                    docker rm -f zap-scan-${BUILD_NUMBER} 2>/dev/null || true
                    docker volume rm zap-reports-${BUILD_NUMBER} 2>/dev/null || true
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
                    export ANSIBLE_HOST_KEY_CHECKING=False
                    export ANSIBLE_SSH_ARGS="-o ConnectTimeout=30 -o ConnectionAttempts=3"

                    # Ensure SSH key permissions
                    chmod 600 /var/jenkins_home/.ssh/id_rsa
                    chmod 700 /var/jenkins_home/.ssh

                    # Move into Ansible directory
                    cd ${WORKSPACE}/ansible

                    # Run playbook (Ansible will fail naturally if SSH/inventory is wrong)
                    ansible-playbook -i inventory/hosts deploy.yml
                    echo "Deployment complete!"
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