Feature: Preconfiguration
  In order to install a Ruby project
  As a Ruby Developer
  I may first use 'setup.rb config' to generate a configuration file

  Scenario: Configure a new project
    Given a setup.rb compliant Ruby project
    When I issue the command 'setup.rb preconfig'
    Then a config file should be generated

  Scenario: Configure a previously configured project
    Given a setup.rb compliant Ruby project
    And 'setup.rb preconfig' has been run
    When I issue the command 'setup.rb preconfig'
    Then the config file should be updated

