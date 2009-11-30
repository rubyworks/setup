When /I issue \'setup.rb install \-\-type\=(.*?)\'$/ do |type|
  Setup::Command.run("install", "--type=#{type}", "--prefix=#{FAUXROOT}")
end

Then /the project should be installed to the site_ruby location$/ do
  entries = Dir[FAUXROOT + "/**/*"]
  entires = entries.reject{ |f| File.basename(f) =~ /^[.]+$/ }
  entries = entries.map{ |f| f.sub(FAUXROOT, '' }
  entries = entries.sort
  entries.assert.include?('/usr/local/bin/faux')
  entries.assert.include?('/usr/local/lib/site_ruby/#{RUBY_VERSION}/faux.rb')
  entries.assert.include?('/usr/local/lib/site_ruby/#{RUBY_VERSION}/faux/mytest.so')
end

