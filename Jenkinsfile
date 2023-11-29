pipeline {
    agent any

    tools {
        jdk 'JDK-17'
        nodejs 'node-16'
    }

    environment {
        SONAR_SCANNER = tool 'Sonar-scanner'
        SONAR_IP = credentials('SQ_PUB_IP')
        SONAR_LOGIN = credentials('SQ_LOGIN')
        DOCKER_CRD = credentials('DOCKER_CRD')
        API = credentials('TMDB_API')
        GITHUB_EMAIL = credentials('GITHUB_E')
        GITHUB = credentials('GITHUB') 
    }

    stages {
        stage('clean workspace') {
            steps {
                cleanWs() 
            }
        }

        stage('Checkout from git') {
            steps {
                git branch: 'main', url: 'https://github.com/chahid001/Netflix-Clone-DevSecOps.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir('app') {
                    withSonarQubeEnv('SonarQube-server') {
                        sh '$SONAR_SCANNER/bin/sonar-scanner \
                            -Dsonar.projectKey=Netflix-clone \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=$SONAR_IP \
                            -Dsonar.login=$SONAR_LOGIN'
                    }
                   
                }
            }
        }

        stage('Quality gate') {
            steps { //Stop the pipeline and check if SonarQube analysis and check quality gate status
                script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'SonarQube-token'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                dir('app') {
                    sh 'npm install'
                }
            }
        }

        stage('OWASP Dependencies Scan') { //Scan 
            steps {
                dir('app') {
                    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                dir('app') {
                    sh 'trivy fs . > trivy_scan.txt'
                }
            }
        }

        stage('Docker Build') {
            steps {
                dir('app') {
                    sh 'docker build --build-arg TMDB_V3_API_KEY=$API -t $DOCKER_CRD_USR/netflix-clone:v$BUILD_NUMBER .'
                }
            }
        }

        stage('Docker Push') {
            steps {
                dir('app') {
                    sh 'docker login -u $DOCKER_CRD_USR -p $DOCKER_CRD_PSW'
                    sh 'docker push $DOCKER_CRD_USR/netflix-clone:v$BUILD_NUMBER'
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image $DOCKER_CRD_USR/netflix-clone:$BUILD_NUMBER > trivy_image_scan.txt'
            }
        }

        stage('Change build number') {
            steps {
                dir("Kubernetes/manifests") {
                    sh 'sed -i -e "s/:v[^ ]*/:v$BUILD_NUMBER/" netflix.deployement.yaml'
                }
            }
        }

        stage('Git push changes') {
            steps {
                sh 'git config user.email $GITHUB_EMAIL'
                sh 'git config user.name $GITHUB_USR'
                sh 'git add Kubernetes/manifests/netflix.deployement.yaml'
                sh 'git commit -m $BUILD_NUMBER'
                sh 'git push https://$GITHUB_USR:$GITHUB_PSW@github.com/$GITHUB_USR/IoT-test.git'
            }
        }

    }
    post {
        always {
            emailext attachLog: true,
                subject: "'${currentBuild.result}'",
                body: "Project: ${env.JOB_NAME}<br/>" +
                    "Build Number: ${env.BUILD_NUMBER}<br/>" +
                    "URL: ${env.BUILD_URL}<br/>",
                to: 'soufianeel288@gmail.com',
                attachmentsPattern: 'trivy_scan.txt,trivy_image_scan.txt'
        }
    }
}