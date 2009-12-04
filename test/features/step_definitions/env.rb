$LOAD_PATH.unshift(File.expand_path("lib"))

require 'ae'
require 'tmpdir'
require 'pathname'
require 'setup/command'

TEMPDIR  = Pathname.new(Dir.tmpdir)

FIXTURE  = Pathname.new('test/fixtures/faux-project').expand_path
FAUXDIR  = TEMPDIR + 'cucumber/setup'
FAUXROOT = TEMPDIR + 'cucumber/setup/faux-root'

def installed_files
  entries = Dir.glob("#{FAUXROOT}/**/*", File::FNM_DOTMATCH)
  entries = entries.reject{ |f| /^\.+$/ =~ File.basename(f) }
  entries = entries.map{ |f| f.sub("#{FAUXROOT}", '') }
  entries = entries.sort
end

def homedir
  if loc = ENV['XDG_LOCAL_HOME'] # TODO: name of this is step up in the air
    File.expand_path(ENV['XDG_LOCAL_HOME'])
  else
    File.expand_path("~") + '/.local'
  end
end

def rbdir
  Config::CONFIG['rubylibdir'].sub(Config::CONFIG['prefix']+'/', '')
end

def sodir
  Config::CONFIG['archdir'].sub(Config::CONFIG['prefix']+'/', '')
end


