pipeline {
    agent any

    environment {
        ORCH_URL = credentials('orch-url')
        ACCOUNT_LOGICAL_NAME = credentials('account-logical-name')
        TENANT_LOGICAL_NAME = credentials('tenant-logical-name')
        FOLDER_NAME = credentials('folder-name')
        APP_ID = credentials('app-id')
        APP_SECRET = credentials('app-secret')
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/isaitej/04-06-2025.git'
            }
        }

        stage('Run UiPath Deployment') {
            steps {
                powershell '''
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    .\\RunDeployment.ps1
                '''
            }
        }
    }
}
