void setBuildStatus(String message, String state) {
  step([
      $class: "GitHubCommitStatusSetter",
      reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/photonia-io/photonia"],
      contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/jenkins/build-status"],
      errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
      statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
  ]);
}

pipeline {
  agent any
  environment {
    PHOTONIA_DATABASE_URL = credentials('photonia-database-url')
  }
  stages {
    stage('Set GitHub state') {
      steps {
        setBuildStatus("Build started", "PENDING");
      }
    }
    stage('Build and test') {
      agent {
        dockerfile {
          args '-e PHOTONIA_DATABASE_URL=$PHOTONIA_DATABASE_URL'
        }
      }
      steps {
        setBuildStatus("Running rspec", "PENDING");
        sh 'bundle exec rspec'
      }   
    }
  }
  post {
    success {
        setBuildStatus("Build succeeded", "SUCCESS");
    }
    failure {
        setBuildStatus("Build failed", "FAILURE");
    }
  }
}
