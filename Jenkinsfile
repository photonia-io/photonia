pipeline {
  environment {
    PHOTONIA_DATABASE_URL = credentials('photonia-database-url')
    PHOTONIA_DEPLOY_HOST = credentials('photonia-deploy-host')
    PHOTONIA_DEPLOY_PORT = credentials('photonia-deploy-port')
    PHOTONIA_DEPLOY_USER = credentials('photonia-deploy-user')
    PHOTONIA_DEPLOY_PATH = credentials('photonia-deploy-path')
    PHOTONIA_DEVISE_JWT_SECRET_KEY = credentials('photonia-devise-jwt-secret-key')
  }
  agent {
    dockerfile {
      args '-u root -e RAILS_ENV=test -e PHOTONIA_DATABASE_URL=$PHOTONIA_DATABASE_URL -e PHOTONIA_DEPLOY_HOST=$PHOTONIA_DEPLOY_HOST -e PHOTONIA_DEPLOY_PORT=$PHOTONIA_DEPLOY_PORT -e PHOTONIA_DEPLOY_USER=$PHOTONIA_DEPLOY_USER -e PHOTONIA_DEPLOY_PATH=$PHOTONIA_DEPLOY_PATH -e PHOTONIA_DEVISE_JWT_SECRET_KEY=$PHOTONIA_DEVISE_JWT_SECRET_KEY'
      additionalBuildArgs "-t photonia-jenkins-build:${env.BRANCH_NAME.replace('/', '-')}-${env.BUILD_NUMBER}"
    }
  }
  stages {
    stage('test') {
      steps {
        sh 'ln -s /usr/src/app/node_modules node_modules'
        sh 'bundle exec rspec --exclude-pattern "spec/system/**/*_spec.rb"'
        sh 'yarn test:run'
      }
    }
    stage('deploy') {
      when {
        tag "release-*"
      }
      steps {
        sshagent (credentials: ['photonia-private-key']) {
          sh "bundle exec cap production deploy BRANCH=${env.BRANCH_NAME}"
        }
      }
    }
  }
  /*
  post {
    always {
      echo 'Clean up Docker images'
      sh 'docker rmi --force $(docker images --quiet --filter=reference="jenkins-test-build")'
    }
  }
  */
}
