Feature: Install
  In order to install a Ruby project
  As a Ruby Developer
  I want to use the setup.rb install command

  Scenario: Install project to Ruby's site locations
    Given a setup.rb compliant Ruby project
    And 'setup.rb config --type=site' has been run
    And 'setup.rb setup' has been run
    When I issue the install command 'setup.rb install'
    Then the project should be installed to the site_ruby location

  Scenario: Install project to standard ruby locations
    Given a setup.rb compliant Ruby project
    And 'setup.rb config --type=std' has been run
    And 'setup.rb setup' has been run
    When I issue the install command 'setup.rb install'
    Then the project should be installed to the standard ruby location

  Scenario: Install project to XDG home locations
    Given a setup.rb compliant Ruby project
    And 'setup.rb config --type=home' has been run
    And 'setup.rb setup' has been run
    When I issue the install command 'setup.rb install'
    Then the project should be installed to the XDG-compliant $HOME location


  Scenario: Install extensionless project to Ruby's site locations
    Given a setup.rb compliant Ruby project
    And the project does NOT have extensions
    And 'setup.rb config --type=site' has been run
    When I issue the install command 'setup.rb install'
    Then the project should be installed to the site_ruby location

  Scenario: Install extensionless project to standard ruby locations
    Given a setup.rb compliant Ruby project
    And the project does NOT have extensions
    And 'setup.rb config --type=std' has been run
    When I issue the install command 'setup.rb install'
    Then the project should be installed to the standard ruby location

  Scenario: Install extensionless project to XDG home locations
    Given a setup.rb compliant Ruby project
    And the project does NOT have extensions
    And 'setup.rb config --type=home' has been run
    When I issue the install command 'setup.rb install'
    Then the project should be installed to the XDG-compliant $HOME location


  Scenario: Fail to install project without first running config
    Given a setup.rb compliant Ruby project
    And 'setup.rb config' has NOT been run
    When I issue the install command 'setup.rb install' unprepared
    Then I will be told that I must first run 'setup.rb config'

  Scenario: Fail to install project with extensions without first running setup
    Given a setup.rb compliant Ruby project
    And 'setup.rb config' has been run
    But 'setup.rb setup' has NOT been run
    When I issue the install command 'setup.rb install' unprepared
    Then I will be told that I must first run 'setup.rb setup'

