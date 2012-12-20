require 'setup/constants'

module Setup

  # Complexities arise in trying to figure out what test framework
  # is used, and how to run tests. To simplify the process, this
  # class simply looks for a special Ruby script at either
  # `.setup/test.rb` or a shell script at `.setup/test.sh` and runs
  # the such script accordingly. The Ruby script has priority if both exist.
  #
  class Tester < Base

    RUBYSCRIPT  = META_EXTENSION_DIR + '/test.rb'

    SHELLSCRIPT = META_EXTENSION_DIR + '/test.sh'

    DEPRECATED_RUBYSCRIPT  = META_EXTENSION_DIR + '/testrc.rb'

    #
    def testable?
      if File.exist?(DEPRECATED_RUBYSCRIPT)
        warn "Must use `.setup/test.rb' instead or `.setup/testrc.rb' to support testing."
      end

      return false if config.no_test
      return true  if File.exist?(RUBYSCRIPT)
      return true  if File.exist?(SHELLSCRIPT)
      false
    end

    #
    def test
      return true unless testable?

      if File.exist?(RUBYSCRIPT)
        test_rubyscript
      elsif File.exist?(SHELLSCRIPT)
        test_shellscript
      else
        true
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


    # DEPRECATED: Since 0.5.0
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
