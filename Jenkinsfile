pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    jenkins: agent
spec:
  serviceAccountName: jenkins
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.19.0-debug
    imagePullPolicy: Always
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
    resources:
      requests:
        cpu: 200m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi
  - name: git
    image: alpine/git:latest
    imagePullPolicy: Always
    command:
    - cat
    tty: true
    resources:
      requests:
        cpu: 50m
        memory: 64Mi
      limits:
        cpu: 200m
        memory: 128Mi
  volumes:
  - name: docker-config
    secret:
      secretName: docker-config
"""
        }
    }
    
    environment {
        // ECR Konfiguration
        ECR_REGISTRY = credentials('ecr-registry')
        ECR_REPOSITORY = 'lesson-5-ecr'
        AWS_REGION = 'eu-central-1'
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // GitHub Konfiguration
        GITHUB_CREDENTIALS_ID = 'github-credentials'
        GITHUB_REPO = 'https://github.com/daria-hk/goit-devops.git'
        GITHUB_USER = 'daria-hk'
        GITHUB_EMAIL = 'jenkins@daria-hk.com'
        
        // Chart Pfad
        CHART_PATH = 'charts/django-app'
        VALUES_FILE = 'charts/django-app/values.yaml'
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                echo "🔍 Checking out source code..."
                checkout scm
            }
        }
        
        stage('Build & Push Docker Image') {
            steps {
                container('kaniko') {
                    script {
                        echo "🔨 Building Docker image with Kaniko..."
                        echo "📦 Image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                        
                        // Kaniko Build & Push zu ECR
                        sh """
                            /kaniko/executor \
                                --context=\${WORKSPACE} \
                                --dockerfile=\${WORKSPACE}/Dockerfile \
                                --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG} \
                                --destination=${ECR_REGISTRY}/${ECR_REPOSITORY}:latest \
                                --cache=true \
                                --compressed-caching=false \
                                --cleanup
                        """
                        
                        echo "✅ Image successfully pushed to ECR!"
                    }
                }
            }
        }
        
        stage('Update Helm Chart') {
            steps {
                container('git') {
                    script {
                        echo "📝 Updating Helm Chart values.yaml..."
                        
                        withCredentials([usernamePassword(
                            credentialsId: GITHUB_CREDENTIALS_ID,
                            usernameVariable: 'GIT_USERNAME',
                            passwordVariable: 'GIT_PASSWORD'
                        )]) {
                            sh """
                                # Git Konfiguration
                                git config --global user.name "${GITHUB_USER}"
                                git config --global user.email "${GITHUB_EMAIL}"
                                git config --global credential.helper store
                                
                                # Credentials für Git speichern
                                echo "https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com" > ~/.git-credentials
                                
                                # Repository klonen (falls nicht bereits vorhanden)
                                if [ ! -d ".git" ]; then
                                    echo "🔄 Cloning repository..."
                                    git clone ${GITHUB_REPO} temp-repo
                                    cd temp-repo
                                else
                                    echo "📂 Using existing repository"
                                    git pull origin lesson-8-9
                                fi
                                
                                # Values.yaml aktualisieren
                                echo "🔄 Updating image tag in ${VALUES_FILE}..."
                                
                                # Sed command zum Aktualisieren des Image Tags
                                sed -i "s|tag:.*|tag: \\"${IMAGE_TAG}\\"|g" ${VALUES_FILE}
                                
                                # Überprüfen ob Änderungen vorhanden sind
                                if git diff --quiet; then
                                    echo "ℹ️  No changes detected in values.yaml"
                                else
                                    echo "✅ Changes detected, committing..."
                                    
                                    # Commit und Push
                                    git add ${VALUES_FILE}
                                    git commit -m "🚀 Update image tag to ${IMAGE_TAG} [Jenkins Build #${BUILD_NUMBER}]"
                                    git push origin lesson-8-9
                                    
                                    echo "✅ Successfully pushed changes to Git!"
                                fi
                            """
                        }
                    }
                }
            }
        }
        
        stage('Verify Deployment') {
            steps {
                echo "✅ Pipeline completed successfully!"
                echo "📦 Image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
                echo "🔄 Helm chart updated in Git"
                echo "⏳ Waiting for Argo CD to sync..."
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline succeeded!"
            echo "🚀 New image: ${ECR_REGISTRY}/${ECR_REPOSITORY}:${IMAGE_TAG}"
            echo "📝 Git commit pushed to main branch"
            echo "🔄 Argo CD will sync automatically"
        }
        failure {
            echo "❌ Pipeline failed!"
            echo "Please check the logs above for errors."
        }
        always {
            echo "🧹 Cleaning up workspace..."
            deleteDir()
        }
    }
}

