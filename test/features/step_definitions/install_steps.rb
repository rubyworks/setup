Given /^'setup\.rb setup' has NOT been run$/ do
  # TODO: assert there are no compiled extensions
end

When /I issue the install command 'setup.rb install'$/ do
  Setup::Command.run("install", "--prefix=#{FAUXROOT}", "--trace")
end

When /I issue the install command 'setup.rb install' unprepared$/ do
  begin
    Setup::Command.run("install", "--prefix=#{FAUXROOT}", "--trace")
  rescue SystemExit => error
    $setup_feature_error = error
  end
end

# TODO: break these into parts, one for each file type (bin, lib, ext, etc.)
Then /the project should be installed to the site_ruby location$/ do
  entries = Dir["#{FAUXROOT}/**/*"]
  entries = entries.map{ |f| f.sub("#{FAUXROOT}", '') }
  entries = entries.sort
  entries.assert.include?('/usr/bin/faux')
  entries.assert.include?("#{Config::CONFIG['sitelibdir']}/faux.rb")
  entries.assert.include?("#{Config::CONFIG['sitearchdir']}/faux.so") unless $setup_no_extensions
end

Then /the project should be installed to the standard ruby location$/ do
  entries = Dir.glob("#{FAUXROOT}/**/*")
  entries = entries.map{ |f| f.sub("#{FAUXROOT}", '') }
  entries = entries.sort
  entries.assert.include?('/usr/bin/faux')
  entries.assert.include?("#{Config::CONFIG['rubylibdir']}/faux.rb")
  entries.assert.include?("#{Config::CONFIG['archdir']}/faux.so") unless $setup_no_extensions
end

Then /^the project should be installed to the XDG\-compliant \$HOME location$/ do
  home  = File.expand_path("~")
  rbdir = Config::CONFIG['rubylibdir'].sub(Config::CONFIG['prefix']+'/', '')
  sodir = Config::CONFIG['archdir'].sub(Config::CONFIG['prefix']+'/', '')
  entries = Dir.glob("#{FAUXROOT}/**/*", File::FNM_DOTMATCH)
  entries = entries.reject{ |f| /^\.+$/ =~ File.basename(f) }
  entries = entries.map{ |f| f.sub("#{FAUXROOT}", '') }
  entries = entries.sort
  entries.assert.include?("#{home}/.local/bin/faux")
  entries.assert.include?("#{home}/.local/#{rbdir}/faux.rb")
  entries.assert.include?("#{home}/.local/#{sodir}/faux.so") unless $setup_no_extensions
end

Then /^I will be told that I must first run 'setup\.rb setup'$/ do
  $setup_feature_error.message.assert =~ /setup\.rb setup first/
end
