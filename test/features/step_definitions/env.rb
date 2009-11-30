$LOAD_PATH.unshift(File.expand_path("lib"))

require 'ae'
require 'tmpdir'
require 'pathname'
require 'setup/command'

TEMPDIR  = Pathname.new(Dir.tmpdir)

FIXTURE  = Pathname.new('test/fixtures/faux-project').expand_path
FAUXDIR  = TEMPDIR + 'cucumber/setup'
FAUXROOT = TEMPDIR + 'cucumber/setup/faux-root'

