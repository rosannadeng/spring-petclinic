pipeline {
    agent any

    tools {
        maven 'Maven 3.9.5'
        jdk 'JDK 25'
    }

    environment {
        SONAR_PROJECT_KEY = 'spring-petclinic'
        DOCKER_ARGS = '-v /var/run/docker.sock:/var/run/docker.sock --user root'
    }

    stages {
        /*********************************************
         * Checkout Source Code
         *********************************************/
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }


        /*********************************************
         * Build with Java 25
         *********************************************/
        stage('Build (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                    network 'spring-petclinic_devops-net'
                }
            }
            steps {
                echo 'Building project with Maven and Java 25...'
                sh './mvnw clean compile'
            }
        }


        /*********************************************
         * Test with Java 25
         *********************************************/
        stage('Test (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                    network 'spring-petclinic_devops-net'
                }
            }
            steps {
                echo 'Running tests...'
                sh './mvnw test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }


        /*********************************************
         * SonarQube Analysis
         *********************************************/
        stage('SonarQube Analysis (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                    network 'spring-petclinic_devops-net'
                }
            }
            steps {
                withSonarQubeEnv('SonarQubeServer') {
                    echo 'Running SonarQube analysis...'
                    sh './mvnw sonar:sonar'
                }
            }
        }


        /*********************************************
         * Quality Gate
         *********************************************/
        stage('Quality Gate') {
            steps {
                echo 'Waiting for SonarQube quality gate result...'
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }


        /*********************************************
         * Checkstyle Code Quality Check
         *********************************************/
        stage('Checkstyle (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                    network 'spring-petclinic_devops-net'
                }
            }
            steps {
                echo 'Running Checkstyle analysis...'
                sh './mvnw checkstyle:checkstyle'
            }
            post {
                always {
                    recordIssues(
                        enabledForFailure: true,
                        tools: [checkstyle(pattern: '**/target/checkstyle-result.xml')]
                    )
                }
            }
        }


        /*********************************************
         * Package Application
         *********************************************/
        stage('Package (Java 25)') {
            agent {
                docker {
                    image 'maven-java25:latest'
                    args "${DOCKER_ARGS}"
                    network 'spring-petclinic_devops-net'
                }
            }
            steps {
                echo 'Packaging application...'
                sh './mvnw package -DskipTests'
            }
        }


        /*********************************************
         * Archive Artifacts
         *********************************************/
        stage('Archive') {
            steps {
                echo 'Archiving artifacts...'
                archiveArtifacts artifacts: '**/target/*.jar', fingerprint: true
            }
        }


        /*********************************************
         * OWASP ZAP Security Scan
         *********************************************/
        stage('OWASP ZAP Scan') {
            steps {
                script {
                    sh '''
                    set +e
                    
                    # Create writable directory
                    mkdir -p zap-reports
                    chmod 777 zap-reports
                    
                    # Run ZAP scan
                    docker run --rm \
                        --network=spring-petclinic_devops-net \
                        -v $(pwd)/zap-reports:/zap/wrk:rw \
                        ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
                        -t http://petclinic:8080 \
                        -r zap_report.html \
                        -I || true
                    
                    # Copy report or create placeholder
                    if [ -f zap-reports/zap_report.html ]; then
                        cp zap-reports/zap_report.html .
                        echo "ZAP report generated"
                    else
                        echo "<html><body><h1>ZAP Scan Report</h1><p>Check console for details</p></body></html>" > zap_report.html
                    fi
                    
                    rm -rf zap-reports
                    '''
                }
            }
        }


        /*********************************************
         * Publish ZAP HTML Report
         *********************************************/
        stage('Publish ZAP Report') {
            steps {
                echo 'Publishing OWASP ZAP report...'
                publishHTML target: [
                    allowMissing: true,
                    reportDir: '.',
                    reportFiles: 'zap_report.html',
                    reportName: 'OWASP ZAP Security Report',
                    keepAll: true
                ]
            }
        }
    }


    /*********************************************
     * Post-Build Actions
     *********************************************/
    post {
        success {
            echo 'Build succeeded!'
        }
        failure {
            echo 'Build failed!'
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}

