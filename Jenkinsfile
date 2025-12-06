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
            echo "=== Create ZAP Volume ==="
            docker volume create zapdata || true

            echo "=== Inject zap.yaml into zapdata volume ==="

            # 将 zap.yaml 写到 volume 里
            docker run --rm \
                -v zapdata:/zap/wrk \
                bash:latest \
                /bin/bash -c 'cat > /zap/wrk/zap.yaml << "EOF"
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
                '

            echo "=== Running ZAP scan using automation framework ==="

            docker run --rm \
                --platform linux/amd64 \
                --network ${DOCKER_NETWORK} \
                -v zapdata:/zap/wrk \
                ghcr.io/zaproxy/zaproxy:weekly \
                zap.sh -cmd -autorun /zap/wrk/zap.yaml || true

            echo "=== Copy ZAP report from volume to Jenkins workspace ==="
            mkdir -p ${WORKSPACE}/zap-reports

            docker run --rm -v zapdata:/zap/wrk -v ${WORKSPACE}/zap-reports:/out \
                bash:latest \
                /bin/bash -c 'cp /zap/wrk/zap-report.html /out/zap-report.html || true'

            ls -la ${WORKSPACE}/zap-reports
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
