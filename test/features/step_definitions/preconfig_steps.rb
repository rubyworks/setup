Given /^'setup\.rb preconfig' has NOT been run$/ do
  #pending
end

Given /^'setup.rb preconfig' has been run$/ do
  Setup::Command.run("preconfig", "--quiet") #, "--trace")
end

Given /^'setup\.rb preconfig \-\-type=(.*?)' has been run$/ do |type|
  Setup::Command.run("preconfig", "--type", type, "--quiet")
end

When /^I issue the command 'setup.rb preconfig'$/ do
  Setup::Command.run("preconfig", "--quiet") #, "--trace")
end

Then /^a config file should be generated$/ do
  File.assert.exists?(Setup::Configuration::CONFIG_FILE)
end

Then /^the config file should be updated$/ do
  File.assert.exists?(Setup::Configuration::CONFIG_FILE)
end

