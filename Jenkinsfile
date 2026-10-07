#!/usr/bin/env groovy

pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    environment {
        DOCKER_REPO_SERVER = '591132357918.dkr.ecr.eu-north-1.amazonaws.com'
        DOCKER_REPO = "${DOCKER_REPO_SERVER}/twn-devops-bootcamp/java-maven-app"
    }

    stages {

        stage('Increment Version') {
            steps {
                script {
                    echo 'Incrementing application version...'

                    sh '''
                        mvn build-helper:parse-version versions:set \
                          -DnewVersion=\\${parsedVersion.majorVersion}.\\${parsedVersion.minorVersion}.\\${parsedVersion.nextIncrementalVersion} \
                          -DgenerateBackupPoms=false
                    '''
                    env.APP_VERSION = sh(
                        script: '''
                            mvn help:evaluate \
                              -Dexpression=project.version \
                              -q \
                              -DforceStdout
                        ''',
                        returnStdout: true
                    ).trim()

                    echo "Application version: ${env.APP_VERSION}"
                }
            }
        }

        stage('build app') {
            steps {
                script {
                    echo 'building the application...'
                    sh 'mvn clean package'
                }
            }
        }
        stage('build image') {
            steps {
                script {

                    env.IMAGE_NAME = "${env.APP_VERSION}-${BUILD_NUMBER}"
                    def imageName =
                    "${env.DOCKER_REPO}:${env.IMAGE_NAME}"

                    echo "building the docker image..."
                    withCredentials([usernamePassword(credentialsId: 'ecr-credentials', passwordVariable: 'PASS', usernameVariable: 'USER')]){
                        sh "docker build -t ${imageName} ."
                        sh "echo $PASS | docker login -u $USER --password-stdin ${DOCKER_REPO_SERVER}"
                        sh "docker push ${imageName}"
                    }
                }
            }
        }
        stage('deploy') {
            environment {
                AWS_ACCESS_KEY_ID = credentials('jenkins_aws_access_key_id')
                AWS_SECRET_ACCESS_KEY = credentials('jenkins-aws_secret_access_key')
                APP_NAME = 'java-maven-app'
            }
            steps {
                script {
                   echo 'deploying docker image...'
                   sh 'envsubst < kubernetes/deployment.yaml | kubectl apply -f -'
                   sh 'envsubst < kubernetes/service.yaml | kubectl apply -f -'
                }
            }
        }


        stage('Commit Version Update') {
            when {
                branch 'commitVersionUpdate'
            }

             steps {

                script {
                            echo "Preparing version commit for ${env.APP_VERSION}"

                   sh '''
                        set -eu

                        git config user.name "Jenkins CI"
                        git config user.email "jenkins-ci@users.noreply.github.com"

                        git add pom.xml

                        echo "Files staged for commit:"
                        git diff --cached --name-only
                    '''

                            def hasChanges = sh(
                                script: 'git diff --cached --quiet',
                                returnStatus: true
                            )

                            if (hasChanges == 0) {
                                echo 'No version change to commit. Skipping commit and push.'
                            } else {
                                sh """
                            git commit \
                              -m "chore(release): bump version to ${env.APP_VERSION}"
                        """

                                withCredentials([
                                    gitUsernamePassword(
                                        credentialsId: 'github-credentials',
                                        gitToolName: 'Default'
                                    )
                                ]) {
                                    sh '''
                                set -eu
                                git push origin HEAD:commitVersionUpdate
                            '''
                                }
                            }
                        }
                    }
                }

            }

            post {
                success {
                    echo "Pipeline completed successfully for version ${env.APP_VERSION}"
                }

                failure {
                    echo 'Pipeline failed.'
                }
           }

}
