Given /^'setup\.rb config' has NOT been run$/ do
  #pending
end

Given /^'setup.rb config' has been run$/ do
  Setup::Command.run("config", "--quiet") #, "--trace")
end

When /^I issue the command 'setup.rb config'$/ do
  Setup::Command.run("config", "--quiet") #, "--trace")
end

Then /^a '\.cache\/setup\/config' file should be generated$/ do
  File.assert.exists?(Setup::Configuration::CONFIG_FILE)
end

Then /^the '\.cache\/setup\/config' file should be updated$/ do
  File.assert.exists?(Setup::Configuration::CONFIG_FILE)
end

