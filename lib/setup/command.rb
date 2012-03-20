require 'setup/session'
require 'optparse'

module Setup

  # Command-line interface for Setup.rb.

  class Command

    # Initialize and run.

    def self.run(*argv)
      new.run(*argv)
    end

    # Hash of <tt>task => description</tt>.

    def self.tasks
      @tasks ||= {}
    end

    # Task names listed in order of information.

    def self.order
      @order ||= []
    end

    # Define a task.

    def self.task(name, description)
      tasks[name] = description
      order << name
    end

    task 'show'     , "show current configuration"
    task 'all'      , "config, compile and install"
    task 'preconfig', "customize configuration settings"
    task 'config'   , "configure extensions"
    task 'compile'  , "compile ruby extentions"
    task 'test'     , "run test suite"
    task 'install'  , "install project files"
    task 'doc'      , "install with documentation (doc/ directory)"
    task 'uninstall', "uninstall previously installed files"
    task 'clean'    , "does `make clean' for each extention"
    task 'distclean', "does `make distclean' for each extention"

    # Run command.

    def run(*argv)
      ARGV.replace(argv) unless argv.empty?

      #session = Session.new(:io=>$stdio)
      #config  = session.configuration

      task = ARGV.find{ |a| a !~ /^[-]/ }
      task = 'all' unless task

      #task = 'doc' if task == 'document'

      unless task_names.include?(task)
        $stderr.puts "Not a valid task -- #{task}"
        exit 1
      end

      parser  = OptionParser.new
      options = {}

      parser.banner = "Usage: #{File.basename($0)} [TASK] [OPTIONS]"

      optparse_header(parser, options)
      case task
      when 'preconfig'
        optparse_preconfig(parser, options)
      when 'config'
        optparse_config(parser, options)
      when 'install'
        optparse_install(parser, options)
      when 'all'
        optparse_all(parser, options)
      end
      optparse_common(parser, options)

      begin
        parser.parse!(ARGV)
      rescue OptionParser::InvalidOption
        $stderr.puts $!.to_s.capitalize
        exit 1
      end

      # This ensures we are in a project directory.
      rootdir = session.project.rootdir

      print_header

      begin
        $stderr.puts "(#{RUBY_ENGINE} #{RUBY_VERSION} #{RUBY_PLATFORM})"
      rescue
        $stderr.puts "(#{RUBY_VERSION} #{RUBY_PLATFORM})"
      end

      begin
        session.__send__(task)
      rescue Error => err
        raise err if $DEBUG
        $stderr.puts $!.message
        $stderr.puts "Try 'setup.rb --help' for detailed usage."
        abort $!.message #exit 1
      end

      puts unless session.quiet?
    end

    # Setup session.

    def session
      @session ||= Session.new(:io=>$stdout)
    end

    # Setup configuration. This comes from the +session+ object.

    def configuration
      @configuration ||= session.configuration
    end

    #
    def optparse_header(parser, options)
      parser.banner = "USAGE: #{File.basename($0)} [command] [options]"
    end

    # Setup options for +all+ task.

    def optparse_all(parser, options)
      optparse_preconfig(parser, options)
      optparse_config(parser, options)
      optparse_install(parser, options)  # TODO: why was this remarked out ?
      #parser.on("-t", "--[no-]test", "run tests (default is --no-test)") do |val|
      #  configuration.no_test = val
      #end
      #parser.on("--[no-]doc", "generate ri/yri documentation (default is --doc)") do |val|
      #  configuration.no_doc = val
      #end
    end

    # Setup options for +config+ task.

    def optparse_preconfig(parser, options)
      parser.separator ""
      parser.separator "Configuration options:"
      #parser.on('--reset', 'reset configuration to default settings') do
      #  session.reset = true
      #end
      configuration.options.each do |args|
        args = args.dup
        desc = args.pop
        type = args.pop
        name, shortcut = *args
        #raise ArgumentError unless name, type, desc
        optname = name.to_s.gsub('_', '-')
        case type
        when :bool
          if optname.index('no-') == 0
            optname = "[no-]" + optname.sub(/^no-/, '')
            opts = shortcut ? ["-#{shortcut}", "--#{optname}", desc] : ["--#{optname}", desc]
            parser.on(*opts) do |val|
              configuration.__send__("#{name}=", !val)
            end
          else
            optname = "[no-]" + optname.sub(/^no-/, '')
            opts = shortcut ? ["-#{shortcut}", "--#{optname}", desc] : ["--#{optname}", desc]
            parser.on(*opts) do |val|
              configuration.__send__("#{name}=", val)
            end
          end
        else
          opts = shortcut ? ["-#{shortcut}", "--#{optname} #{type.to_s.upcase}", desc] :
                            ["--#{optname} #{type.to_s.upcase}", desc]
          parser.on(*opts) do |val|
            configuration.__send__("#{name}=", val)
          end
        end
      end
    end

    #
    def optparse_config(parser, options)
    end

    # Setup options for +install+ task.

    def optparse_install(parser, options)
      parser.separator ''
      parser.separator 'Install options:'
      # install prefix overrides target prefix when installing
      parser.on('--prefix PATH', 'install to alternate root location') do |val|
        configuration.install_prefix = val
      end
      ## type can be set without preconfig
      #parser.on('-T', '--type TYPE', "install location mode (site,std,home)") do |val|
      #  configuration.type = val
      #end
    end

    # Setup options for +test+ task.

    #def optparse_test(parser, options)
    #  parser.separator ""
    #  parser.separator "Test options:"
    #  parser.on("--runner TYPE", "Test runner (auto|console|gtk|gtk2|tk)") do |val|
    #    ENV['RUBYSETUP_TESTRUNNER'] = val
    #  end
    #end

    # Setup options for +uninstall+ task.

    #def optparse_uninstall(parser, options)
    #  parser.separator ""
    #  parser.separator "Uninstall options:"
    #  parser.on("--prefix [PATH]", "Installation prefix") do |val|
    #    session.options[:install_prefix] = val
    #  end
    #end

    # Common options for every task.

    def optparse_common(parser, options)
      parser.separator ""
      parser.separator "General options:"

      parser.on("-q", "--quiet", "Suppress output") do
        session.quiet = true
      end

      parser.on("-f", "--force", "Force operation") do
        session.force = true
      end

      parser.on("--trace", "--verbose", "Watch execution") do |val|
        session.trace = true
      end

      parser.on("--trial", "--no-harm", "Do not write to disk") do |val|
        session.trial = true
      end

      parser.on("--debug", "Turn on debug mode") do |val|
        $DEBUG = true
      end

      parser.separator ""
      parser.separator "Inform options:"

      # Tail options (eg. commands in option form)
      parser.on_tail("-h", "--help", "display this help information") do
        #puts help
        puts parser
        exit
      end

      parser.on_tail("--version", "-v", "Show version") do
        puts File.basename($0) + ' v' + Setup::VERSION #Version.join('.')
        exit
      end

      parser.on_tail("--copyright", "Show copyright") do
        puts Setup::COPYRIGHT #opyright
        exit
      end
    end

    # List of task names.
    #--
    # TODO: shouldn't this use +self.class.order+ ?
    #++

    def task_names
      #self.class.order
      self.class.tasks.keys
    end

    # Output Header.
    #
    # TODO: This is not yet used. It might be nice to have,
    # but not sure what it should contain or look like.

    def print_header
      #unless session.quiet?
      #  if session.project.name
      #    puts "= #{session.project.name} (#{rootdir})"
      #  else
      #    puts "= #{rootdir}"
      #  end
      #end
      #$stderr << "#{session.options.inspect}\n" if session.trace? or session.trial?
    end

  end

end

