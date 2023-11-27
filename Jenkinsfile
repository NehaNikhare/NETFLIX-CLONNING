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
                sh 'trivy fs app/* > trivy_scan.txt'
            }
        }

        stage('Docker Build') {
            steps {
                dir('app') {
                    sh 'docker build TMDB_V3_API_KEY=$API -t $DOCKER_CRD_USR/netflix-clone:$BUILD_NUMBER .'
                }
            }
        }

        stage('Docker Push') {
            steps {
                dir('app') {
                    sh 'docker login -u $DOCKER_CRD_USR -p $DOCKER_CRD_PSW'
                    sh 'docker push $DOCKER_CRD_USR/netflix-clone:$BUILD_NUMBER'
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image $DOCKER_CRD_USR/netflix-clone:$BUILD_NUMBER > trivy_image_scan.txt'
            }
        }

        stage('Deploy Container') {
            steps {
                sh 'docker run -d --name netflix -p 8081:80 $DOCKER_CRD_USR/netflix-clone:$BUILD_NUMBER'
            }
        }
    }
}