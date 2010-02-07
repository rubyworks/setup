Given /'setup.rb make' has been run$/ do
  Setup::Command.run("make", "--quiet") #, "--trace")
end

When /^I issue the command 'setup\.rb make'$/ do
  Setup::Command.run("make", "--quiet")
end

When /^I issue the command 'setup\.rb make' unprepared$/ do
  begin
    Setup::Command.run("make", "--quiet")
  rescue SystemExit => error
    $setup_feature_error = error
  end
end

Then /^the extensions should be compiled$/ do
  exts = Dir['ext/faux/faux.so']
  exts.assert!.empty?
end

Then /^I will be told that I must first run 'setup\.rb config'$/ do
  $setup_feature_error.message.assert == "must run \'setup config\' first"
end

Then /^the extensions will not be compiled$/ do
  exts = Dir['ext/faux/faux.so']
  exts.assert.empty?
end

