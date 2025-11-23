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
  serviceAccountName: jenkins-kaniko-sa
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args:
      - "--context=dir://workspace"
      - "--dockerfile=/workspace/Dockerfile"
      - "--destination=\${ECR_REGISTRY}/\${ECR_REPO}:\${IMAGE_TAG}"
      - "--cache=true"
    volumeMounts:
      - name: kaniko-secret
        mountPath: /kaniko/.docker
  - name: git
    image: alpine/git:latest
    command:
      - cat
    tty: true
  - name: awscli
    image: amazon/aws-cli:2.9.0
    command:
      - cat
    tty: true
  volumes:
    - name: kaniko-secret
      emptyDir: {}
"""
    }
  }
  environment {
    ECR_REGISTRY = '606705194042.dkr.ecr.us-west-2.amazonaws.com'
    ECR_REPO = 'lesson-5-ecr'
    CHART_PATH = 'charts/django-app/values.yaml'
  }
  stages {
    stage('Prepare') {
      steps {
        container('git') {
          checkout scm
          script {
            IMAGE_TAG = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
            env.IMAGE_TAG = IMAGE_TAG
          }
        }
      }
    }

    stage('Build & Push image (Kaniko)') {
      steps {
        script {
          withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
                           string(credentialsId: 'git-ssh-key', variable: 'GIT_SSH_KEY')]) {
            sh '''
            mkdir -p ~/.docker
            cat > ~/.docker/config.json <<EOF
            {"credsStore":"ecr-login"}
            EOF
            '''
          }
        }
        container('kaniko') {
          sh '''
          echo "Running Kaniko..."
          # Kaniko reads AWS creds from environment variables
          /kaniko/executor \
            --context ${WORKSPACE} \
            --dockerfile ${WORKSPACE}/Dockerfile \
            --destination ${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG} \
            --cache=true
          '''
        }
      }
    }

    stage('Update Helm chart values.yaml') {
      steps {
        container('git') {
          sh """
          git config user.email "ci@example.com"
          git config user.name "ci-bot"
          yq eval -i '.image.tag = env(IMAGE_TAG)' ${CHART_PATH}
          git add ${CHART_PATH}
          git commit -m "ci: bump image tag to ${IMAGE_TAG} [skip ci]" || echo "no changes to commit"
          git push origin HEAD:main
          """
        }
      }
    }

    stage('Helm lint & template (optional)') {
      steps {
        container('awscli') {
          sh '''
          # optionally run helm lint locally (if helm available in image) - many setups run helm from Jenkins master job or agent with helm
          echo "Helm checks (run in Jenkins or separate job as needed)"
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
