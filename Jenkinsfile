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
        // stage('Checkout') {
        //     steps {
        //         checkout scm
        //     }
        // }

        // stage('Build') {
        //     agent {
        //         docker {
        //             image 'maven-java25:latest'
        //             args "--network ${DOCKER_NETWORK}"
        //             reuseNode true
        //         }
        //     }
        //     steps {
        //         sh '''
        //             chmod +x ./mvnw
        //             ./mvnw clean compile -DskipTests -q
        //         '''
        //     }
        // }

        // stage('Test') {
        //     agent {
        //         docker {
        //             image 'maven-java25:latest'
        //             args "--network ${DOCKER_NETWORK}"
        //             reuseNode true
        //         }
        //     }
        //     steps {
        //         sh '''
        //             chmod +x ./mvnw
        //             ./mvnw test -Dtest="!PostgresIntegrationTests" -q
        //         '''
        //     }
        // }

        // stage('SonarQube Analysis') {
        //     agent {
        //         docker {
        //             image 'maven-java25:latest'
        //             args "--network ${DOCKER_NETWORK}"
        //             reuseNode true
        //         }
        //     }
        //     steps {
        //         script {
        //             withSonarQubeEnv('SonarQubeServer') {
        //                 sh '''
        //                     chmod +x ./mvnw
        //                     ./mvnw sonar:sonar \
        //                         -Dsonar.projectKey=spring-petclinic \
        //                         -Dsonar.projectName=spring-petclinic || echo "SonarQube analysis failed, continuing..."
        //                 '''
        //             }
        //         }
        //     }
        // }

        // stage('Package') {
        //     agent {
        //         docker {
        //             image 'maven-java25:latest'
        //             args "--network ${DOCKER_NETWORK}"
        //             reuseNode true
        //         }
        //     }
        //     steps {
        //         sh '''
        //             chmod +x ./mvnw
        //             ./mvnw package -DskipTests -q
        //         '''
        //     }
        //     post {
        //         success {
        //             archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
        //         }
        //     }
        // }

        stage('OWASP ZAP Baseline Scan') {
            steps {
                sh '''
                    echo "=== Prepare report directory ==="
                    mkdir -p "${WORKSPACE}/zap-reports"
                    chmod -R 777 "${WORKSPACE}/zap-reports"

                    echo "=== Running OWASP ZAP Baseline Scan ==="
                    
                    # Run ZAP in a named container to copy files later
                    docker run --name zap-scan-${BUILD_NUMBER} \
                      --platform linux/amd64 \
                      --network ${DOCKER_NETWORK} \
                      ghcr.io/zaproxy/zaproxy:stable \
                      zap-baseline.py \
                        -t http://petclinic:8080 \
                        -r zap-report.html \
                        -w zap-report.md \
                        -x zap-report.xml \
                        -I || true
                    
                    echo ""
                    echo "=== Copying reports from container ==="
                    docker cp zap-scan-${BUILD_NUMBER}:/zap/wrk/zap-report.html "${WORKSPACE}/zap-reports/" 2>/dev/null || echo "HTML report not found"
                    docker cp zap-scan-${BUILD_NUMBER}:/zap/wrk/zap-report.md "${WORKSPACE}/zap-reports/" 2>/dev/null || echo "MD report not found"
                    docker cp zap-scan-${BUILD_NUMBER}:/zap/wrk/zap-report.xml "${WORKSPACE}/zap-reports/" 2>/dev/null || echo "XML report not found"
                    docker cp zap-scan-${BUILD_NUMBER}:/zap/wrk/zap.yaml "${WORKSPACE}/zap-reports/" 2>/dev/null || echo "YAML config not found"
                    
                    echo ""
                    echo "=== Cleanup container ==="
                    docker rm -f zap-scan-${BUILD_NUMBER} 2>/dev/null || true

                    echo ""
                    echo "=== ZAP report directory ==="
                    ls -lah "${WORKSPACE}/zap-reports/"
                    
                    echo ""
                    echo "=== Report status ==="
                    for file in zap-report.html zap-report.md zap-report.xml zap.yaml; do
                        if [ -f "${WORKSPACE}/zap-reports/$file" ]; then
                            size=$(stat -c%s "${WORKSPACE}/zap-reports/$file" 2>/dev/null || stat -f%z "${WORKSPACE}/zap-reports/$file" 2>/dev/null)
                            echo "✓ $file ($size bytes)"
                        else
                            echo "✗ $file NOT found"
                        fi
                    done
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

    //    stage('Deploy to Production') {
    //         steps {
    //             sh '''
    //                 export ANSIBLE_HOST_KEY_CHECKING=False
    //                 export ANSIBLE_SSH_ARGS="-o ConnectTimeout=30 -o ConnectionAttempts=3"

    //                 # Ensure SSH key permissions
    //                 chmod 600 /var/jenkins_home/.ssh/id_rsa
    //                 chmod 700 /var/jenkins_home/.ssh

    //                 # Move into Ansible directory
    //                 cd ${WORKSPACE}/ansible

    //                 # Run playbook (Ansible will fail naturally if SSH/inventory is wrong)
    //                 ansible-playbook -i inventory/hosts deploy.yml
    //                 echo "Deployment complete!"
    //             '''
    //         }
    //     }
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
