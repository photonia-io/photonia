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
    stage('reset test database') {
      steps {
        sh 'bundle exec rails db:reset RAILS_ENV=test'
      }
    }
    stage('migrate') {
      steps {
        sh 'bundle exec rails db:migrate RAILS_ENV=test'
      }
    }
    stage('test') {
      steps {
        sh 'bundle exec rspec'
      }   
    }
  }
}
