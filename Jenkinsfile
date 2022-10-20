pipeline {
  agent {
    docker {
      image 'ruby:2.6.7'
      args "-e PHOTONIA_DATABASE_URL=${PHOTONIA_DATABASE_URL}"
    }
  }
  stages {
    stage('requirements') {
      steps {
        sh 'gem install bundler -v 2.2.26'
      }
    }
    stage('build') {
      steps {
        sh 'env'
        sh 'bundle install'
      }
    }
    stage('test') {
      steps {
        sh 'bundle exec rspec'
      }   
    }
  }
}
