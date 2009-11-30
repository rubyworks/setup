#When /^I issue 'setup\.rb setup'$/ do
#  system "#{SETUPCMD} setup"
#end

Then /^the extensions should be compiled$/ do
  exts = Dir['ext/mytest/mytest.so']
  exts.assert!.empty?
end

Then /^I will be told that I must first run 'setup\.rb config'$/ do
  $setup_feature_error.message.assert == "must setup config first"
end

Then /^the extensions will not be compiled$/ do
  exts = Dir['ext/mytest/mytest.so']
  exts.assert.empty?
end

