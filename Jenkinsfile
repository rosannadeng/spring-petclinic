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

        stage('OWASP ZAP Scan') {
            steps {
                sh '''
                    mkdir -p "${WORKSPACE}/zap-wrk"

                    cat > "${WORKSPACE}/zap-wrk/zap.yaml" << 'EOF'
        ---
        env:
        contexts:
            - name: petclinic-context
            urls:
                - http://petclinic:8080
            includePaths:
                - http://petclinic:8080.*
            excludePaths: []

        jobs:
        - type: spider
            parameters:
            context: petclinic-context
            url: http://petclinic:8080
            maxDuration: 2

        - type: activeScan
            parameters:
            context: petclinic-context
            policy: Default Policy
            maxRuleDurationInMins: 3
            addQueryParam: true

        - type: passiveScan-wait

        - type: report
            parameters:
            template: traditional-html
            reportDir: /zap/wrk
            reportFile: zap-report.html
        EOF

                    chown -R 1000:1000 "${WORKSPACE}/zap-wrk"

                    docker run --rm \
                    --platform linux/amd64 \
                    --network ${DOCKER_NETWORK} \
                    -v "${WORKSPACE}/zap-wrk":/zap/wrk \
                    ghcr.io/zaproxy/zaproxy:weekly \
                    zap.sh -cmd -autorun /zap/wrk/zap.yaml

                    cp "${WORKSPACE}/zap-wrk/zap-report.html" "${WORKSPACE}/zap-reports/" || true
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
