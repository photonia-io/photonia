pipeline {
  environment {
    PHOTONIA_DATABASE_URL = credentials('photonia-database-url')
  }
  agent {
    dockerfile {
      args '-u root -e PHOTONIA_DATABASE_URL=$PHOTONIA_DATABASE_URL'
      additionalBuildArgs "-t photonia-jenkins-build:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
    }
  }
  stages {
    stage('test') {
      steps {
        sh 'ln -s /usr/src/app/node_modules node_modules'
        sh 'RAILS_ENV=test bundle exec rails webpacker:compile'
        sh 'RAILS_ENV=test bundle exec rspec'
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
