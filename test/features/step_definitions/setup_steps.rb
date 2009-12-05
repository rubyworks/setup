Given /'setup.rb setup' has been run$/ do
  Setup::Command.run("setup", "--quiet") #, "--trace")
end

When /^I issue the command 'setup\.rb setup'$/ do
    Setup::Command.run("setup", "--quiet")
end

When /^I issue the command 'setup\.rb setup' unprepared$/ do
  begin
    Setup::Command.run("setup", "--quiet")
  rescue SystemExit => error
    $setup_feature_error = error
  end
end

Then /^the extensions should be compiled$/ do
  exts = Dir['ext/faux/faux.so']
  exts.assert!.empty?
end

Then /^I will be told that I must first run 'setup\.rb config'$/ do
  $setup_feature_error.message.assert == "must setup config first"
end

Then /^the extensions will not be compiled$/ do
  exts = Dir['ext/faux/faux.so']
  exts.assert.empty?
end

