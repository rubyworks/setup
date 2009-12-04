Given /^'setup\.rb setup' has NOT been run$/ do
  # TODO: assert there are no compiled extensions
end

Given /'setup.rb install' has been run$/ do
  Setup::Command.run("install", "--prefix=#{FAUXROOT}", "--quiet") #, "--trace")
end

When /I issue the command 'setup\.rb install'$/ do
  Setup::Command.run("install", "--prefix=#{FAUXROOT}", "--quiet") #, "--trace")
end

When /I issue the command 'setup.rb install' unprepared$/ do
  begin
    Setup::Command.run("install", "--prefix=#{FAUXROOT}", "--quiet") #, "--trace")
  rescue SystemExit => error
    $setup_feature_error = error
  end
end

Then /^I will be told that I must first run 'setup\.rb setup'$/ do
  $setup_feature_error.message.assert =~ /setup\.rb setup first/
end

# Site Ruby Locations

Then /the project's exectuables should be installed to the site_ruby bin location$/ do
  entries = installed_files
  entries.assert.include?('/usr/bin/faux')
end

Then /the project's libraries should be installed to the site_ruby lib location$/ do
  entries = installed_files
  entries.assert.include?("#{Config::CONFIG['sitelibdir']}/faux.rb")
end

Then /the project's extensions should be installed to the site_ruby arch location$/ do
  entries = installed_files
  entries.assert.include?("#{Config::CONFIG['sitearchdir']}/faux.so")
end

# Ruby Locations

Then /the project's exectuables should be installed to the ruby bin location$/ do
  entries = installed_files
  entries.assert.include?('/usr/bin/faux')
end

Then /the project's libraries should be installed to the ruby lib location$/ do
  entries = installed_files
  entries.assert.include?("#{Config::CONFIG['rubylibdir']}/faux.rb")
end

Then /the project's extensions should be installed to the ruby arch location$/ do
  entries = installed_files
  entries.assert.include?("#{Config::CONFIG['archdir']}/faux.so")
end

# Home Locations

Then /the project's exectuables should be installed to the home bin location$/ do
  entries = installed_files
  entries.assert.include?("#{homedir}/bin/faux")
end

Then /the project's libraries should be installed to the home lib location$/ do
  entries = installed_files
  entries.assert.include?("#{homedir}/#{rbdir}/faux.rb")
end

Then /the project's extensions should be installed to the home arch location$/ do
  entries = installed_files
  entries.assert.include?("#{homedir}/#{sodir}/faux.so")
end

