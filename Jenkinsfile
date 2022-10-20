pipeline {
  environment {
    PHOTONIA_DATABASE_URL = credentials('photonia-database-url')
    HOME = '/photonia'
  }
  agent {
    dockerfile {
      args '-e PHOTONIA_DATABASE_URL=$PHOTONIA_DATABASE_URL -v bundle:/root/.bundle'
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
