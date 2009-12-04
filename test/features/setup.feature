Feature: Setup/Compile Extensions
  In order to install a Ruby project with extensions
  As a Ruby Developer
  I must first use 'setup.rb setup' to buld the extensions

  Scenario: Compile a new project
    Given a setup.rb compliant Ruby project
    And 'setup.rb config' has been run
    When I issue the command 'setup.rb setup'
    Then the extensions should be compiled

  Scenario: Fail to compile project without first running config
    Given a setup.rb compliant Ruby project
    And 'setup.rb config' has NOT been run
    When I issue the command 'setup.rb setup' unprepared
    Then I will be told that I must first run 'setup.rb config'
    And the extensions will not be compiled

