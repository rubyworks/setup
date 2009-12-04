require 'setup/session'
require 'optparse'

module Setup

  # CLI for Setup.rb
  class Command

    #
    def self.run(*argv)
      new.run(*argv)
    end

    #
    def self.tasks
      @tasks ||= {}
    end

    #
    def self.order
      @order ||= []
    end

    #
    def self.task(name, description)
      tasks[name] = description
      order << name
    end

    task 'all'      , "do config, setup, then install"
    task 'config'   , "saves your configuration"
    task 'show'     , "show current configuration"
    task 'setup'    , "compile ruby extentions"
    task 'test'     , "run tests"
    task 'document' , "generate ri documentation"
    #task 'rdoc'     , "generate rdoc documentation"
    task 'install'  , "install project files"
    task 'uninstall', "uninstall previously installed files"
    task 'clean'    , "does `make clean' for each extention"
    task 'distclean', "does `make distclean' for each extention"

    #
    def run(*argv)
      ARGV.replace(argv) unless argv.empty?

      #session = Session.new(:io=>$stdio)
      #config  = session.configuration

      task = ARGV.find{ |a| a !~ /^[-]/ }
      task = 'all' unless task

      unless task_names.include?(task)
        $stderr.puts "Not a valid task -- #{task}"
        exit 1
      end

      parser  = OptionParser.new
      options = {}

      parser.banner = "Usage: #{File.basename($0)} [TASK] [OPTIONS]"

      optparse_header(parser, options)
      case task
      when 'all'
        optparse_all(parser, options)
      when 'config'
        optparse_config(parser, options)
      when 'install'
        optparse_install(parser, options)
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
        session.__send__(task)
      rescue Error
        raise if $DEBUG
        $stderr.puts $!.message
        $stderr.puts "Try 'setup.rb --help' for detailed usage."
        exit 1
      end

      puts unless session.quiet?
    end

    #
    def session
      @session ||= Session.new(:io=>$stdout)
    end

    #
    def configuration
      @configuration ||= session.configuration
    end

    #
    def optparse_header(parser, options)
      parser.banner = "USAGE: #{File.basename($0)} [command] [options]"
    end

    #
    def optparse_all(parser, options)
      optparse_config(parser, options)
      #optparse_install(parser, options)
      #parser.on("--no-test", "do not run tests") do
      #  configuration.no_test = true
      #end
      #parser.on("--no-doc", "do not generate ri documentation") do
      #  configuration.no_doc = true
      #end
    end

    #
    def optparse_config(parser, options)
      parser.separator ""
      parser.separator "Configuration options:"
      configuration.options.each do |name, type, desc|
        optname = name.to_s.gsub('_', '-')
        case type
        when :bool
          if optname.index('no-') == 0
            optname = "[no-]" + optname.sub(/^no-/, '')
            parser.on("--#{optname}", desc) do |val|
              configuration.__send__("#{name}=", !val)
            end
          else
            optname = "[no-]" + optname.sub(/^no-/, '')
            parser.on("--#{optname}", desc) do |val|
              configuration.__send__("#{name}=", val)
            end
          end
        else
          parser.on("--#{optname} #{type.to_s.upcase}", desc) do |val|
            configuration.__send__("#{name}=", val)
          end
        end
      end
    end

    #
    def optparse_install(parser, options)
      parser.separator ""
      parser.separator "Install options:"
      parser.on("--prefix PATH", "Installation prefix") do |val|
        #session.options[:install_prefix] = val
        configuration.install_prefix = val
      end
    end

    #def optparse_test(parser, options)
    #  parser.separator ""
    #  parser.separator "Install options:"
    #
    #  parser.on("--runner TYPE", "Test runner (auto|console|gtk|gtk2|tk)") do |val|
    #    ENV['RUBYSETUP_TESTRUNNER'] = val
    #  end
    #end

    #
    def optparse_uninstall(parser, options)
      #parser.separator ""
      #parser.separator "Uninstall options:"
      #parser.on("--prefix [PATH]", "Installation prefix") do |val|
      #  session.options[:install_prefix] = val
      #end
    end

    # Common options
    def optparse_common(parser, options)
      parser.separator ""
      parser.separator "General options:"

      parser.on("-q", "--quiet", "Suppress output") do |val|
        session.options[:quiet] = val
      end

      parser.on("--trace", "--verbose", "Watch execution") do |val|
        session.options[:trace] = true
      end

      parser.on("--trial", "--no-harm", "Do not write to disk") do |val|
        session.options[:trial] = true
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

    #
    def task_names
      self.class.tasks.keys
    end

    # TODO: Might be nice to have a ouput header, but not sure
    # what it should conatin or look like yet.
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

=begin
    # Generate help text
    def help
    fmt = " " * 12 + "%-10s       %s"
      commands = self.class.order.collect do |k|
        d = self.class.tasks[k]
        (fmt % ["#{k}", d])
      end.join("\n").strip

      fmt = " " * 13 + "%-20s       %s"
      configs = configuration.options.collect do |k,t,d|
        (fmt % ["--#{k}", d])
      end.join("\n").strip

      text = <<-END
        USAGE: #{File.basename($0)} [command] [options]

        Commands:
            #{commands}

        Options for CONFIG:
            #{configs}

        Options for INSTALL:
            --prefix                      Set the install prefix

        Options in common:
            -q --quiet                    Silence output
               --verbose                  Provide verbose output
            -n --no-write                 Do not write to disk

      END
      text.gsub(/^\ {8,8}/, '')
    end
=end

  end
end
