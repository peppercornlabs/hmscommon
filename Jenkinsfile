

//@library('cicdjenkins') _
library identifier: 'cicdjenkins@master', retriever: modernSCM(
    [$class: 'GitSCMSource',
    remote: 'git@spruce.arlo.com:ARLO/cicdjenkins.git',
    credentialsId: 'svc.devops-ut']
)

/*
FileName : Jenkinsfile (Build)
Purpouse : Usefull to Build Code & generate Image
Description:
UPDATE: update for Kubernetes plugin support
*/
pipeline {
    agent { 
        kubernetes {
            label 'hmscommon'
            defaultContainer 'jnlp'
            yamlFile 'hmscommon/Jenkins.yaml' 
        }
}
    environment {
        ENVIRONMENT='DEV'
        DOCKER_REGISTRY='artifactory.arlocloud.com'
        S3_BUCKET='s3-dev-secret-store'
        S3_FILENAME='application.properties'
        DOCKER_REGISTRY_CRED_ID="DCR_PROD"
    }
    stages {
        /*
        Stage : Pre-Build Step
        Purpouse : notify slack about JOB started
        */
        stage('General') {
            steps {
                notify('STARTED')
                githubstatus('STARTED')
                script {
                //find out who kicked off the build
                    USER = wrap([$class: 'BuildUser']) {
                        return env.BUILD_USER
                    }
                }      
            }
        }
        /*
        Stage : Build Environment
        Purpouse : setup variables for further use in Job
        */
        stage('Build Environment') {
            steps {
                script {
                    VERSION = sh(returnStdout: true, script: '''grep "docker.image.tag" hmscommon/pom.xml | cut -f2 -d">" | cut -f1 -d"<" | head -n 1''').trim()
                    GIT_REVISION = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
            }
        }
        /*
        Stage : Build
        Purpouse : Build code using maven & generate Image 
        */
        stage('Build') {
            steps {
                container('maven') {
                    script {
                        DOCKER_BUILD_NUMBER = VERSION+"-"+BUILD_NUMBER+"-"+GIT_REVISION
                        echo "$DOCKER_BUILD_NUMBER"
                        sh "chmod 755 hmscommon/build.sh"
                        sh "hmscommon/build.sh "+DOCKER_BUILD_NUMBER
                    }
                }
            }
        }
		
        /*
														Stage : SonarQube Report publish
														Purpouse : Publish sobarqube report to sonarqube server
														
														stage('sonarqube') {
															steps {
																container('maven') {
																	script {
																		withSonarQubeEnv('SonarQube') {
																			sh 'mvn sonar:sonar ' +
																			'-f hmscommon/pom.xml ' +
																			'-Dsonar.projectKey=hmsgoogle ' +
																			'-Dsonar.language=java ' +
																			'-Dsonar.sources=src/main ' +
																			'-Dsonar.tests=src/test ' +
																			'-Dsonar.java.binaries=target/ '+
																			'-Dsonar.java.coveragePlugin=jacoco	' +
																			'-Dsonar.jacoco.reportPaths=target/jacoco.exec ' +
																			'-Dsonar.junit.reportPaths=target/surefire-reports ' +
																			'-Dsonar.verbose=true ' +
																			'-Dsonar.log.level=TRACE '
																		}
																	}
																}
															}
														}
														
		*/												
														
        /*
        Stage : Docker Push
        Purpouse : Push docker image into docker Registry
        */
        stage('Docker Push'){
            steps {
                container('docker') {
                    script {
                        withDockerRegistry([credentialsId: "${DOCKER_REGISTRY_CRED_ID}", url: "http://${DOCKER_REGISTRY}"]) {
                            sh "docker tag hmscommon:"+VERSION+" ${DOCKER_REGISTRY}/hmscommon:"+DOCKER_BUILD_NUMBER+" && docker push ${DOCKER_REGISTRY}/hmscommon:"+DOCKER_BUILD_NUMBER
                        }
                    }
                }
            }
        } 
    }
    /*
    Post Build Actions
    Purpouse : Perform slack Notification,Generate Junit & Jacoco Reports & trigger Deploy job for related environment
    */
    post {
        success {
            //Add short Text
            addShortText(text: "${USER}", background: 'orange', border: 1) ;
            addShortText(text: "${GIT_BRANCH}", background: 'yellow', border: 1);
            addShortText(text: "${NODE_NAME}", background: 'cyan', border: 1) ;
            addShortText(text: "${DOCKER_BUILD_NUMBER}", background: 'cyan', border: 1) ;
            //Notify to github about Build status
            githubstatus(currentBuild.result) 
            //Sidebar GIT repo link
            sidebarlinks()
            //Notify Slack
            notify(currentBuild.result)
			
            //Junit Report Plugin
           // junit 'hmscommon/target/surefire-reports/*.xml'
            //Jacoco Code coverage Report
            // jacoco classPattern: 'hmscommon/target', execPattern: 'hmscommon/target/**.exec', sourcePattern: 'hmscommon/src/main/java'
            //Trigger Deploy Job
           // trigger_build("${ENVIRONMENT}",DOCKER_BUILD_NUMBER)
        } 
    }
}

/*
Function Name : trigger_build

Purpouse : Trigger Deployment JOB with specified environemnt & Docker build number
Parameters:
    environment = (Dev|QA|QA2) On which environment you want to deploy
    DOCKER_BUILD_NUMBER = Tag og the Image that you want to deploy on Kubernetes cluster
*/
def trigger_build(ENVIRONMENT,DOCKER_BUILD_NUMBER){
    build(job: "CD-hmscommon/master",
        parameters:
        [string(name: 'ENVIRONMENT', value: ENVIRONMENT),
         string(name: 'DOCKER_BUILD_NUMBER', value: DOCKER_BUILD_NUMBER)],
         propagate: false,
         wait: false
    )
}
