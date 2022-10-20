pipeline {
  environment {
    PHOTONIA_DATABASE_URL = credentials('photonia-database-url')
  }
  agent {
    dockerfile {
      args '-e PHOTONIA_DATABASE_URL=$PHOTONIA_DATABASE_URL'
    }
  }
  stages {
    stage('migrate') {
      steps {
        sh 'bundle rails db:migrate RAILS_ENV=test'
      }
    }
    stage('test') {
      steps {
        sh 'bundle exec rspec'
      }   
    }
  }
}
