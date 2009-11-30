Given /a setup\.rb compliant Ruby project$/ do
  FileUtils.rm_r(FAUXDIR) if FAUXDIR.exist?
  FileUtils.mkdir_p(FAUXDIR)
  FileUtils.cp_r(FIXTURE, FAUXDIR)
  dir = FAUXDIR + FIXTURE.basename
  Dir.chdir(dir)
end

Given /the project does NOT have extensions$/ do
  FileUtils.rm_r('ext')
end

Given /^'setup\.rb (.*?)' has already been run$/ do |cmd|
  argv = cmd.split(/\s+/)
  Setup::Command.run(*argv)
end

Given /^'setup\.rb config' has NOT been run$/ do
  #pending
end

When /^I issue the command 'setup.rb (.*?)'$/ do |cmd|
  argv = cmd.split(/\s+/)
  Setup::Command.run(*argv)
end

When /^I issue the command 'setup.rb (.*?)' unprepared$/ do |cmd|
  begin
    argv = cmd.split(/\s+/)
    Setup::Command.run(*argv)
  rescue SystemExit => error
    $setup_feature_error = error
  end
end

