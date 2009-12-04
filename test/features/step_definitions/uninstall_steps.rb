When /^I issue the command 'setup.rb uninstall'$/ do
  #Setup::Command.run("uninstall", "--quiet") #, "--trace")
end

Then /^the package files should be removed$/ do
  installed_files.assert.empty?
end

