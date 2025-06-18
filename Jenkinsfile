pipeline {
    agent any

    environment {
        ORCH_URL = credentials('orch_url')
        TENANT_LOGICAL_NAME = credentials('tenant_logical_name')
        FOLDER_NAME = credentials('folder_name')
        ACCOUNT_LOGICAL_NAME = credentials('account_logical_name')
        APP_ID = credentials('app_id')
        APP_SECRET = credentials('app_secret')
        UIPCLI_PATH = "${WORKSPACE}\\tools\\uipcli.exe"
        PROJECT_OUTPUT = "${WORKSPACE}"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/isaitej/04-06-2025.git'
            }
        }

        stage('Pack Project') {
            steps {
                echo "Packing project using UiPath CLI..."
                bat """
                    "${UIPCLI_PATH}" pack "${WORKSPACE}" --output "${PROJECT_OUTPUT}"
                """
            }
        }

        stage('Deploy Package') {
            steps {
                echo "Deploying package to Orchestrator..."
                bat """
                    "${UIPCLI_PATH}" push --url "${ORCH_URL}" --tenant "${TENANT_LOGICAL_NAME}" ^
                        --folder "${FOLDER_NAME}" --account-name "${ACCOUNT_LOGICAL_NAME}" ^
                        --client-id "${APP_ID}" --client-secret "${APP_SECRET}" ^
                        --package-path "${PROJECT_OUTPUT}\\*.nupkg"
                """
            }
        }

        stage('Trigger Test Set') {
            steps {
                echo "Triggering test set..."
                bat """
                    "${UIPCLI_PATH}" test run --url "${ORCH_URL}" --tenant "${TENANT_LOGICAL_NAME}" ^
                        --folder "${FOLDER_NAME}" --account-name "${ACCOUNT_LOGICAL_NAME}" ^
                        --client-id "${APP_ID}" --client-secret "${APP_SECRET}" ^
                        --test-set "Your_Test_Set_Name"
                """
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
