Given /'setup.rb compile' has been run$/ do
  Setup::Command.run("compile", "--quiet") #, "--trace")
end

When /^I issue the command 'setup\.rb compile'$/ do
  Setup::Command.run("compile", "--quiet")
end

When /^I issue the command 'setup\.rb install' unprepared$/ do
  begin
    Setup::Command.run("install", "--quiet")
  rescue SystemExit => error
    $setup_feature_error = error
  end
end

Then /^the extensions should be compiled$/ do
  exts = Dir['ext/faux/faux.so']
  exts.assert!.empty?
end

Then /^I will be told that I must first run 'setup\.rb compile'$/ do
  $setup_feature_error.message.assert == "must run \'setup compile\' first"
end

Then /^the extensions will not be compiled$/ do
  exts = Dir['ext/faux/faux.so']
  exts.assert.empty?
end

