pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: kaniko
spec:
  serviceAccountName: jenkins-sa
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:latest
      args:
        - "--context=${WORKSPACE}"
        - "--dockerfile=${WORKSPACE}/Dockerfile"
        - "--destination=${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
        - "--cache=true"
      tty: true
    - name: git
      image: alpine/git:latest
      command: ["cat"]
      tty: true
    - name: awscli
      image: amazon/aws-cli:2.9.0
      command: ["cat"]
      tty: true
"""
    }
  }

  environment {
    ECR_REGISTRY = '601710820863.dkr.ecr.eu-central-1.amazonaws.com'
    ECR_REPO     = 'lesson-5-ecr'
    AWS_REGION   = 'eu-central-1'

    CHART_PATH   = 'charts/django-app/values.yaml'

    TARGET_BRANCH = 'main'
  }

  stages {

    stage('Checkout') {
      steps {
        container('git') {
          checkout scm

          script {
            def tag = sh(
              returnStdout: true,
              script: "git rev-parse --short HEAD"
            ).trim()
            env.IMAGE_TAG = tag
            echo "IMAGE_TAG = ${env.IMAGE_TAG}"
          }
        }
      }
    }

    stage('Build & Push image (Kaniko)') {
      steps {
withCredentials([
          usernamePassword(
            credentialsId: 'aws-ecr-creds',
            usernameVariable: 'AWS_ACCESS_KEY_ID',
            passwordVariable: 'AWS_SECRET_ACCESS_KEY'
          )
        ]) {
          container('kaniko') {
            sh '''
              echo "Building & pushing image with Kaniko..."

              export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
              export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
              export AWS_REGION="${AWS_REGION}"
              export AWS_DEFAULT_REGION="${AWS_REGION}"

              /kaniko/executor \
                --context "${WORKSPACE}" \
                --dockerfile "${WORKSPACE}/Dockerfile" \
                --destination "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}" \
                --cache=true
            '''
          }
        }
      }
    }

    stage('Update Helm values.yaml') {
      steps {
        container('git') {
            withCredentials([
            usernamePassword(
              credentialsId: 'github-creds',
              usernameVariable: 'GIT_USER',
              passwordVariable: 'GIT_TOKEN'
            )
          ]) {
            sh '''
              set -e

              git config user.email "ci@example.com"
              git config user.name "ci-bot"

              echo "Updating image.tag in ${CHART_PATH} to ${IMAGE_TAG}"

              sed -i "s/^  tag:.*/  tag: \\"${IMAGE_TAG}\\"/" "${CHART_PATH}"

              git add "${CHART_PATH}"
              git commit -m "ci: bump image tag to ${IMAGE_TAG} [skip ci]" || echo "No changes to commit"

              REPO_URL="$(git remote get-url origin)"
              REPO_URL_CLEAN="${REPO_URL#https://}"
              git remote set-url origin "https://${GIT_USER}:${GIT_TOKEN}@${REPO_URL_CLEAN}"

              git push origin HEAD:${TARGET_BRANCH}
            '''
          }
        }
      }
    }
  }

  post {
    always {
      echo "Pipeline finished"
    }
  }
}
