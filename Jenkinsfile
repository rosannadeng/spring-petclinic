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
                    # 创建目录
                    mkdir -p "${WORKSPACE}/zap-wrk"
                    mkdir -p "${WORKSPACE}/zap-reports"

                    # 将你的 zap.yaml 放到 zap-wrk 中
                    cp "${WORKSPACE}/zap/zap.yaml" "${WORKSPACE}/zap-wrk/zap.yaml"

                    echo ">>> Jenkins workspace:"
                    ls -la "${WORKSPACE}/zap-wrk"

                    # 赋予 ZAP 运行权限
                    chown -R 1000:1000 "${WORKSPACE}/zap-wrk"

                    # 正确运行 docker run（关键：使用 Jenkins 容器路径）
                    docker run --rm \
                    --platform linux/amd64 \
                    --network ${DOCKER_NETWORK} \
                    -v "${WORKSPACE}/zap-wrk":/zap/wrk \
                    ghcr.io/zaproxy/zaproxy:weekly \
                    zap.sh -cmd -autorun /zap/wrk/zap.yaml

                    echo ">>> ZAP workdir content after scan:"
                    ls -la "${WORKSPACE}/zap-wrk"
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'zap-wrk',
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
