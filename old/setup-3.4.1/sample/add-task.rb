#
# add original task using hook file
#

ToplevelInstaller::TASKS.push ['test', 'run test.']
ToplevelInstaller.module_eval {
  def exec_test
    raise "test.rb not given; cannot test this package."\
        unless File.file?("#{srcdir_root()}/test.rb")
    old = Dir.pwd
    Dir.chdir srcdir_root()
    load 'test.rb'
    Dir.chdir old
  end
}
