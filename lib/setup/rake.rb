require 'setup/install'
require 'rake/clean'

setup = Setup::Installer.new

desc 'Config, setup and then install'
task :all => [:config, :setup, :install]

desc 'Saves your configurations'
task :config do
  setup.exec_config
end

desc 'Compiles ruby extentions'
task :setup do
  setup.exec_setup
end

desc 'Runs unit tests'
task :test do
  setup.exec_test 
end

desc 'Generate rdoc documentation'
task :rdoc do
  setup.exec_rdoc
end

desc 'Generate ri documentation'
task :ri do
  setup.exec_ri
end

desc 'Installs files'
task :install do
  setup.exec_install
end

desc 'Uninstalls files'
task :uninstall do
  setup.exec_uninstall
end

#desc "Does `make clean' for each extention"
task :makeclean do
  setup.exec_clean
end

task :clean => [:makeclean]

#desc  "Does `make distclean' for each extention"
task :distclean do
  exec_distclean
end

task :clobber => [:distclean]

desc 'Shows current configuration'
task :show do
  setup.exec_show
end

