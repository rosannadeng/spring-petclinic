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
            post {
                always {
                    junit testResults: '**/target/surefire-reports/*.xml', allowEmptyResults: true
                }
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

        stage('OWASP ZAP Scan') {
            steps {
                sh '''
                    echo "Running ZAP baseline scan..."

                    # Remove previous local report directory
                    mkdir -p ${WORKSPACE}/zap-reports
                    rm -f ${WORKSPACE}/zap-reports/zap-report.html

                    # Run ZAP (write INSIDE container, NOT to the mounted /zap/wrk)
                    docker exec zap zap-baseline.py \
                        -t http://petclinic:8080 \
                        -r /tmp/zap-report.html \
                        -I --autooff || echo "ZAP scan finished with warnings"

                    # Copy report OUT of the container
                    docker cp zap:/tmp/zap-report.html ${WORKSPACE}/zap-reports/zap-report.html || {
                        echo "<html><body><h1>ZAP Scan Failed</h1></body></html>" > ${WORKSPACE}/zap-reports/zap-report.html
                    }

                    echo "ZAP report copied to workspace."
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
