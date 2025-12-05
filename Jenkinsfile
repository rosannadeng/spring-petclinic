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
                    set +e
                    ZAP_WORKDIR="${WORKSPACE}/zap-wrk"
                    mkdir -p "${WORKSPACE}/zap-reports" "${ZAP_WORKDIR}"

                    echo "Waiting for petclinic to be ready for scanning..."
                    for i in {1..30}; do
                        if docker run --rm --network ${DOCKER_NETWORK} curlimages/curl:8.10.1 -s -f http://petclinic:8080 > /dev/null 2>&1; then
                            echo "✓ Petclinic is accessible"
                            break
                        fi
                        echo "Waiting for petclinic... ($i/30)"
                        sleep 2
                    done

                    echo "Running ZAP baseline scan..."
                    rm -f "${ZAP_WORKDIR}/zap-report.html" "${ZAP_WORKDIR}/zap_out.json"
                    docker run --rm \
                        --network ${DOCKER_NETWORK} \
                        -v "${ZAP_WORKDIR}":/zap/wrk \
                        ghcr.io/zaproxy/zaproxy:stable \
                        zap-baseline.py \
                        -t http://petclinic:8080 \
                        -r zap-report.html \
                        -I --autooff
                    ZAP_EXIT_CODE=$?

                    if [ -f "${ZAP_WORKDIR}/zap-report.html" ]; then
                        cp "${ZAP_WORKDIR}/zap-report.html" "${WORKSPACE}/zap-reports/"
                        [ -f "${ZAP_WORKDIR}/zap_out.json" ] && cp "${ZAP_WORKDIR}/zap_out.json" "${WORKSPACE}/zap-reports/" || true
                        echo "ZAP report copied to workspace."
                    else
                        echo "<html><body><h1>ZAP Scan Failed</h1><p>Exit code: $ZAP_EXIT_CODE</p></body></html>" > "${WORKSPACE}/zap-reports/zap-report.html"
                        echo "ZAP report not found; created placeholder."
                    fi

                    echo "Files in ZAP workdir:"
                    ls -la "${ZAP_WORKDIR}" || true
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
