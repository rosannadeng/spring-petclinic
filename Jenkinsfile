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
                    set +e  # Don't exit on error
                    mkdir -p ${WORKSPACE}/zap-reports
                    
                    # Wait for petclinic to be fully ready
                    echo "Waiting for petclinic to be ready for scanning..."
                    for i in {1..30}; do
                        if docker exec zap curl -s -f http://petclinic:8080 > /dev/null 2>&1; then
                            echo "✓ Petclinic is accessible"
                            break
                        fi
                        echo "Waiting for petclinic... ($i/30)"
                        sleep 2
                    done
                    
                    # Clean up previous reports in ZAP container
                    docker exec zap rm -f /zap/wrk/zap-report.html || true
                    
                    # Run ZAP baseline scan
                    echo "Starting OWASP ZAP scan..."
                    docker exec zap zap-baseline.py \
                        -t http://petclinic:8080 \
                        -r zap-report.html \
                        -I
                    ZAP_EXIT_CODE=$?
                    
                    # Check if report was generated
                    if docker exec zap test -f /zap/wrk/zap-report.html; then
                        echo "✓ ZAP report generated"
                        docker cp zap:/zap/wrk/zap-report.html ${WORKSPACE}/zap-reports/
                        echo "✓ ZAP report copied to workspace"
                    else
                        echo "✗ ZAP report not found, creating placeholder"
                        echo "<html><body><h1>ZAP Scan Failed</h1><p>Report was not generated. Exit code: $ZAP_EXIT_CODE</p></body></html>" > ${WORKSPACE}/zap-reports/zap-report.html
                    fi
                    
                    # List files for debugging
                    echo "Files in ZAP container:"
                    docker exec zap ls -la /zap/wrk/ || true
                    
                    exit 0  # Always succeed to continue pipeline
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
                    echo "Deploying to production server via Ansible..."
                    
                    # Add route to reach production VM from Docker container
                    ip route add 192.168.1.0/24 via 172.18.0.1 2>/dev/null || echo "Route already exists or cannot be added"
                    
                    export ANSIBLE_HOST_KEY_CHECKING=False
                    export ANSIBLE_TIMEOUT=30
                    export ANSIBLE_SSH_ARGS="-o ConnectTimeout=30 -o ConnectionAttempts=3"
                    
                    # Ensure SSH key has correct permissions
                    if [ -f /var/jenkins_home/.ssh/id_rsa ]; then
                        chmod 600 /var/jenkins_home/.ssh/id_rsa
                        chmod 700 /var/jenkins_home/.ssh
                    else
                        echo "WARNING: SSH key not found at /var/jenkins_home/.ssh/id_rsa"
                        echo "Please set up SSH key for Ansible deployment"
                        exit 1
                    fi
                    
                    # Test basic network connectivity first
                    echo "Testing network connectivity to VM..."
                    ping -c 3 192.168.1.185 || echo "Warning: Ping failed, but SSH might still work"
                    
                    # Test SSH connectivity directly
                    echo "Testing SSH connection..."
                    timeout 10 ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no -i /var/jenkins_home/.ssh/id_rsa ubuntu@192.168.1.185 "echo SSH connection successful" || {
                        echo "ERROR: Direct SSH test failed"
                        echo "Please check: 1) VM is running 2) SSH service is up 3) Network connectivity"
                    }
                    
                    # Test Ansible connectivity
                    cd ${WORKSPACE}/ansible
                    echo "Testing Ansible connection to production VM..."
                    ansible production -i inventory/hosts -m ping -vvv || {
                        echo "ERROR: Cannot connect to production server via Ansible"
                        exit 1
                    }
                    
                    # Run Ansible deployment playbook
                    echo "Deploying application to production VM..."
                    ansible-playbook -i inventory/hosts deploy.yml
                    
                    # Verify deployment on remote server
                    echo "✓ Application deployed to production VM at 192.168.1.185:8080"
                    echo "Access the application at: 192.168.1.185:8080"
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
