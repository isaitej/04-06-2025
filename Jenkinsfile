pipeline {
    agent any

    environment {
        PROJECT_JSON = 'project.json'
        PROJECT_NAME = 'TestAutomationProject'
        OUTPUT_FOLDER = 'Output'
        ORCH_URL = 'https://cloud.uipath.com/uipatntvskhu/DefaultTenant'
        TENANT = 'DefaultTenant'
        FOLDER_NAME = 'Shared'
        ACCOUNT = 'uipatntvskhu'
        APP_ID = '9765da03-dd43-4915-8847-8fe03d64bfa8'
        APP_SECRET = credentials('UIPATH_APP_SECRET') // Add this in Jenkins > Manage Credentials
    }

    stages {
        stage('Clean') {
            steps {
                bat "if exist %OUTPUT_FOLDER% rmdir /s /q %OUTPUT_FOLDER%"
                bat "mkdir %OUTPUT_FOLDER%"
            }
        }

        stage('Pack UiPath Project') {
            steps {
                bat "\"C:\\Users\\Saiteja.Indarapu\\AppData\\Local\\Programs\\UiPath\\Studio\\UiRobot.exe\" pack %PROJECT_JSON% -o %OUTPUT_FOLDER%"
            }
        }

        stage('Deploy to Orchestrator') {
            steps {
                bat "powershell scripts/UiPathDeploy.ps1 -PackagePath %OUTPUT_FOLDER% -OrchUrl %ORCH_URL% -Tenant %TENANT% -Folder %FOLDER_NAME% -AccountForApp %ACCOUNT% -ApplicationId %APP_ID% -ApplicationSecret %APP_SECRET%"
            }
        }
    }
}
