pipeline {
  environment {
    PHOTONIA_DATABASE_URL = credentials('photonia-database-url')
  }
  agent {
    dockerfile {
      args '-e PHOTONIA_DATABASE_URL=$PHOTONIA_DATABASE_URL'
      additionalBuildArgs "-t photonia-jenkins-build:${env.BUILD_NUMBER}"
    }
  }
  stages {
    stage('test') {
      steps {
        sh 'bundle exec rspec'
      }   
    }
  }
}
