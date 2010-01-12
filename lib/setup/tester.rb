require 'setup/constants'

module Setup

  # Complexities arise in trying to figure out what test framework
  # is used, and how to run tests. To simplify the process, this
  # class simply looks for a special script, this can be  a shell
  # script at <tt>script/test</tt>, or a ruby script that
  # <tt>.setup/testrc.rb</tt> will be used instead if it exists.

  class Tester < Base

    RUBYSCRIPT  = META_EXTENSION_DIR + '/testrc.rb'

    SHELLSCRIPT = 'script/test'

    #
    def testable?
      return false if config.no_test
      return true  if File.exist?(RUBYSCRIPT)
      return true  if File.exist?(SHELLSCRIPT)
      false
    end

    #
    def test
      return true if !testable?
      if File.exist?(RUBYSCRIPT)
        test_rubyscript
      elsif File.exist?(SHELLSCRIPT)
        test_shellscript
      end
    end

    #
    def test_shellscript
      bash(SHELLSCRIPT)
    end

    #
    def test_rubyscript
      ruby(RUBYSCRIPT)
    end


    # DEPRECATED
    #def test
      #runner = config.testrunner
      #case runner
      #when 'testrb'  # TODO: needs work
      #  opt = []
      #  opt << " -v" if trace?
      #  opt << " --runner #{runner}"
      #  if File.file?('test/suite.rb')
      #    notests = false
      #    opt << "test/suite.rb"
      #  else
      #    notests = Dir["test/**/*.rb"].empty?
      #    lib = ["lib"] + config.extensions.collect{ |d| File.dirname(d) }
      #    opt << "-I" + lib.join(':')
      #    opt << Dir["test/**/{test,tc}*.rb"]
      #  end
      #  opt = opt.flatten.join(' ').strip
      #  # run tests
      #  if notests
      #    $stderr.puts 'no test in this package' if trace?
      #  else
      #    cmd = "testrb #{opt}"
      #    $stderr.puts cmd if trace?
      #    system cmd  #config.ruby "-S testrb", opt
      #  end
      #else # autorunner
      #  unless File.directory?('test')
      #    $stderr.puts 'no test in this package' if trace?
      #    return
      #  end
      #  begin
      #    require 'test/unit'
      #  rescue LoadError
      #    setup_rb_error 'test/unit cannot loaded.  You need Ruby 1.8 or later to invoke this task.'
      #  end
      #  lib = ["lib"] + config.extensions.collect{ |d| File.dirname(d) }
      #  lib.each{ |l| $LOAD_PATH << l }
      #  autorunner = Test::Unit::AutoRunner.new(true)
      #  autorunner.to_run << 'test'
      #  autorunner.run
      #end
    #end

  end

end
