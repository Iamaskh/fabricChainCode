pipeline {
   agent any


   stages {
      stage('Code Checkout') {
         steps {
                git branch: 'master',
                url: 'https://github.com/Iamaskh/fabricChainCode.git'
                  }
      }
   

	stage('Code Quality') {
                   steps {
                       script {
                          def scannerHome = tool 'fosslinxsonar';
                          withSonarQubeEnv("fosslinxSonarqubeserver") {
                          sh "${tool("fosslinxsonar")}/bin/sonar-scanner"
                                       }
                               }
                           }
                        }
}
}

