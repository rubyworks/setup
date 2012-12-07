#!/usr/bin/env ruby

require 'fileutils'

VERSION = YAML.load_file('.index')['version']

COMMENT = <<-HERE
# Setup.rb v#{VERSION}
#
# This is a stand-alone bundle of the setup.rb application.
# You can place it in your projects script/ directory, or
# call it 'setup.rb' and place it in your project's
# root directory (just like old times).
#
# NOTE: As of version 5.1.0 this bundled rendition is also
# being used for the bin/setup.rb exe. Rather than the previous:
#
#   require 'setup/command'
#   Setup::Command.run
#
# By doing so, +rvm+ should be able to use it across all rubies
# without issue and without needing to install it for each.
HERE


desc "run cucumber features"
task :test do
  sh "cucumber --format progress test/features"
end

desc "generate bundled scripts"
task :bundle do
  raise "Not the right place #{Dir.pwd}" unless File.directory?('lib')

  #scripts = (Dir['lib/*.rb'] + Dir['lib/**/*']).uniq
  #scripts = scripts.reject{ |f| File.directory?(f) }
  # We don't want the rake helper.
  #scripts = scripts - ["lib/setup/rake.rb"]
  #scripts = scripts + ["bin/setup.rb"]

  scripts = %w{
    lib/setup.rb
    lib/setup/version.rb
    lib/setup/core_ext.rb
    lib/setup/constants.rb
    lib/setup/project.rb
    lib/setup/session.rb
    lib/setup/base.rb
    lib/setup/compiler.rb
    lib/setup/configuration.rb
    lib/setup/installer.rb
    lib/setup/tester.rb
    lib/setup/uninstaller.rb
    lib/setup/command.rb
  }

  #
  bundle = ""

  # insert scripts
  scripts.each do |script|
    bundle << "\n\n# %-16s #{"#" * 60}\n\n" % File.basename(script)
    bundle << File.read(script)
  end
  bundle << "\nSetup::Command.run"

  # remove setup requires
  bundle.gsub!(/require\s+["']setup\/(.*?)["']\s*$/, '')

  # remove blank lines
  bundle.gsub!(/^\s*\n/, '')

  # remove comments
  bundle.gsub!(/^\s*\#.*?\n/, '')

  # save
  File.open('setup.rb', 'w') do |f|
    f << "#!/usr/bin/env ruby\n"
    f << COMMENT
    f << bundle
  end
  FileUtils.chmod(0744, 'setup.rb')

  File.open('bin/setup.rb', 'w') do |f|
    f << "#!/usr/bin/env ruby\n"
    f << COMMENT
    f << bundle
  end
  FileUtils.chmod(0744, 'bin/setup.rb')
end

# Ya know, I don't recall by we had to replace bin/setup.rb
# with the bundled script instead of using this code. It
# had something to do with `rvm`, but I don't see why it was
# now. Any way, just wanted to make a note of that.
desc "run setup on itself"
task :bootstrap do
  #!/usr/bin/env ruby
  $LOAD_PATH.unshift('lib')
  require 'setup/command'
  Setup::Command.run(*ARGV)
end

