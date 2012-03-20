Feature: Setup/Compile Extensions
  In order to install a Ruby project with extensions
  As a Ruby Developer
  I must first use 'setup.rb compile' to buld the extensions

  Scenario: Compile a new project
    Given a setup.rb compliant Ruby project
    And 'setup.rb compile' has been run
    Then the extensions should be compiled

  Scenario: Fail to install project without first running compile
    Given a setup.rb compliant Ruby project
    And 'setup.rb compile' has NOT been run
    When I issue the command 'setup.rb install' unprepared
    Then I will be told that I must first run 'setup.rb config'
    And the extensions will not be compiled

