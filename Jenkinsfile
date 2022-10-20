pipeline {
  agent { docker { image 'ruby:2.6.7' } }
  stages {
    stage('requirements') {
      steps {
        sh 'gem install bundler -v 2.2.26'
      }
    }
    stage('build') {
      steps {
        sh 'bundle install'
      }
    }
    stage('test') {
      steps {
        sh 'rake'
      }   
    }
  }
}
