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
    CHART_PATH   = 'charts/django-app/values.yaml'
  }

  stages {

    stage('Prepare') {
      steps {
        container('git') {
          // Repo in Workspace ziehen
          checkout scm

          script {
            // IMAGE_TAG global über env setzen (Git Commit Hash kurz)
            env.IMAGE_TAG = sh(
              returnStdout: true,
              script: "git rev-parse --short HEAD"
            ).trim()
            echo "Using IMAGE_TAG=${env.IMAGE_TAG}"
          }
        }
      }
    }

    stage('Build & Push image (Kaniko)') {
      steps {
        container('kaniko') {
          // AWS Creds in den Kaniko-Container injizieren
          withCredentials([
            usernamePassword(
              credentialsId: 'aws-creds',
              usernameVariable: 'AWS_ACCESS_KEY_ID',
              passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )
          ]) {
            sh '''
            echo "Running Kaniko..."

            # Optional: Docker config anlegen, falls Credential Helper genutzt wird
            mkdir -p /root/.docker
            cat > /root/.docker/config.json <<EOF
            {"credsStore":"ecr-login"}
            EOF

            /kaniko/executor \
              --context $WORKSPACE \
              --dockerfile $WORKSPACE/Dockerfile \
              --destination $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG \
              --cache=true
            '''
          }
        }
      }
    }

    stage('Update Helm chart values.yaml') {
      steps {
        container('git') {
          // Git Push über SSH-Key aus Jenkins-Credential
          withCredentials([
            string(credentialsId: 'git-ssh-key', variable: 'GIT_SSH_KEY')
          ]) {
            sh '''
            # Tools installieren
            apk add --no-cache yq openssh

            # SSH Key vorbereiten
            mkdir -p /root/.ssh
            echo "$GIT_SSH_KEY" > /root/.ssh/id_rsa
            chmod 600 /root/.ssh/id_rsa

            # StrictHostKeyChecking ausschalten (oder Hostkeys sauber managen)
            echo "Host *" > /root/.ssh/config
            echo "    StrictHostKeyChecking no" >> /root/.ssh/config

            export GIT_SSH_COMMAND="ssh -i /root/.ssh/id_rsa -o StrictHostKeyChecking=no"

            git config user.email "ci@example.com"
            git config user.name "ci-bot"

            # image.tag in values.yaml auf neues IMAGE_TAG setzen
            yq eval -i '.image.tag = env(IMAGE_TAG)' "$CHART_PATH"

            git status
            git add "$CHART_PATH"
            git commit -m "ci: bump image tag to $IMAGE_TAG [skip ci]" || echo "no changes to commit"
            git push origin HEAD:main
            '''
          }
        }
      }
    }

    stage('Helm lint & template (optional)') {
      steps {
        container('awscli') {
          sh '''
          echo "Helm checks können hier ausgeführt werden (lint, template, usw.)"
          '''
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
