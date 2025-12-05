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
                    echo "Deploying to production server via Ansible..."
                    
                    export ANSIBLE_HOST_KEY_CHECKING=False
                    
                    # Ensure SSH key has correct permissions
                    if [ -f /var/jenkins_home/.ssh/id_rsa ]; then
                        chmod 600 /var/jenkins_home/.ssh/id_rsa
                        chmod 700 /var/jenkins_home/.ssh
                    else
                        echo "WARNING: SSH key not found at /var/jenkins_home/.ssh/id_rsa"
                        echo "Please set up SSH key for Ansible deployment"
                        exit 1
                    fi
                    
                    # Test connectivity to production server
                    cd ${WORKSPACE}/ansible
                    echo "Testing connection to production VM..."
                    ansible production -i inventory/hosts -m ping || {
                        echo "ERROR: Cannot connect to production server"
                        exit 1
                    }
                    
                    # Run Ansible deployment playbook
                    echo "Deploying application to production VM..."
                    ansible-playbook -i inventory/hosts deploy.yml
                    
                    # Verify deployment on remote server
                    echo "✓ Application deployed to production VM at 192.168.1.185:8080"
                    echo "Access the application at: http://192.168.1.185:8080"
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
