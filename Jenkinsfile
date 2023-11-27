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
    }

    stages {
        stage('clean workspace') {
            steps {
                cleanWS()
            }
        }

        stage('Checkout from git') {
            steps {
                git branch: 'main', url: 'https://github.com/chahid001/Netflix-Clone-DevSecOps.git'
            }
        }

        stage('SonarQube') {
            withSonarQubeEnv('SONAR_SCANNER') {
                dir('app') {
                    sh '$SONAR_SCANNER/bin/sonar-scanner \
                            -Dsonar.projectKey=Netflix-clone \
                            -Dsonar.sources=. \
                            -Dsonar.host.url=$SONAR_IP \
                            -Dsonar.login=$SONAR_LOGIN'
                }
            }
        }
    }
}