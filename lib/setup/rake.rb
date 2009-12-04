require 'setup/install'
require 'rake/clean'

def session
  @session ||= Setup::Session.new(:io=>$stdout)
end

namespace :setup do

  desc 'Config, setup and then install'
  task :all => [:config, :setup, :install]

  desc 'Saves your configurations'
  task :config do
    session.config
  end

  desc 'Compiles ruby extentions'
  task :setup do
    session.setup
  end

  desc 'Runs unit tests'
  task :test do
    session.test
  end

  desc 'Generate ri documentation'
  task :rdoc do
    session.document
  end

  desc 'Installs files'
  task :install do
    session.install
  end

  desc 'Uninstalls files'
  task :uninstall do
    session.uninstall
  end

  desc "Does `make clean' for each extention"
  task :clean do
    session.clean
  end

  desc  "Does `make distclean' for each extention"
  task :distclean do
    session.distclean
  end

  desc 'Shows current configuration'
  task :show do
    session.show
  end
end

task :clean   => ['setup:clean']
task :clobber => ['setup:distclean']

