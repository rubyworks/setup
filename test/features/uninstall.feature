Feature: Uninstall
  In order to uninstall a Ruby project
  That was installed with setup.rb
  I use 'setup.rb uninstall'

  Scenario: Uninstall a package
    Given a setup.rb compliant Ruby project
    And 'setup.rb config' has been run
    And 'setup.rb setup' has been run
    And 'setup.rb install' has been run
    When I issue the command 'setup.rb uninstall'
    Then the package files should be removed

