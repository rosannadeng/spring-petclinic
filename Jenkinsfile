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
                    
                    docker run --rm \
                      --platform linux/amd64 \
                      --network ${DOCKER_NETWORK} \
                      -v "${WORKSPACE}/zap-reports":/zap/wrk:rw \
                      --user root \
                      ghcr.io/zaproxy/zaproxy:stable \
                      bash -c "
                        set -x
                        chmod -R 777 /zap/wrk
                        echo 'Current directory before:' && pwd
                        echo 'Contents of /zap/wrk before:' && ls -la /zap/wrk
                        
                        su -c 'cd /zap/wrk && pwd && zap-baseline.py -t http://petclinic:8080 -r zap-report.html -w zap-report.md -x zap-report.xml -I' zap || true
                        
                        echo 'Contents of /zap/wrk after:' && ls -laR /zap/wrk
                        echo 'Searching for report files:' && find /zap -name '*zap-report*' -o -name 'zap.yaml' 2>/dev/null || true
                      "

                    echo ""
                    echo "=== ZAP report directory (Jenkins side) ==="
                    ls -lah "${WORKSPACE}/zap-reports/"
                    
                    echo ""
                    echo "=== Searching for any generated files ==="
                    find "${WORKSPACE}/zap-reports/" -type f 2>/dev/null || echo "No files found"
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
