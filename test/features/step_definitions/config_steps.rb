Then /^a '\.cache\/setup\/config' file should be generated$/ do
  File.assert.exists?('SetupConfig')
  #File.assert.exists?('.cache/setup/config')
end

Then /^the '\.cache\/setup\/config' file should be updated$/ do
  File.assert.exists?('SetupConfig')
  #File.assert.exists?('.cache/setup/config')
end

