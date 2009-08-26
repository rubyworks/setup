require 'setup/config'
require 'setup/build'
require 'setup/install'
require 'setup/error'

module Setup

  # CLI for Setup.rb
  class Command

    TASKS = %w(all config show setup test install uninstall rdoc ri clean distclean)

    TASK_DESCRIPTIONS = [
      [ 'all',       "do config, setup, then install" ],
      [ 'config',    "saves your configurations" ],
      [ 'show',      "shows current configuration" ],
      [ 'setup',     "compiles ruby extentions and others" ],
      [ 'rdoc',      "generate rdoc documentation" ],
      [ 'ri',        "generate ri documentation" ],
      [ 'install',   "installs files" ],
      [ 'uninstall', "uninstalls files" ],
      [ 'test',      "run all tests in test/" ],
      [ 'clean',     "does `make clean' for each extention" ],
      [ 'distclean', "does `make distclean' for each extention" ]
    ]

    #
    def self.run(*argv)
      new.run(*argv)
    end

    #
    def run(*argv)
      ARGV.replace(argv) unless argv.empty?

      config    = ConfigTable.new
      installer = Installer.new(config)

      task = ARGV.find{ |a| a !~ /^[-]/ }
      task = 'all' unless task

      unless TASKS.include?(task)
        $stderr.puts "Not a valid task -- #{task}"
        exit 1
      end

      opts   = OptionParser.new

      opts.banner = "Usage: #{File.basename($0)} [task] [options]"

      if task == 'config' or task == 'all'
        opts.separator ""
        opts.separator "Config options:"
        config.descriptions.each do |name, type, desc|
          opts.on("--#{name} #{type.to_s.upcase}", desc) do |val|
            ENV[name.to_s] = val.to_s
          end
        end
      end

      if task == 'install'
        opts.separator ""
        opts.separator "Install options:"

        opts.on("--prefix PATH", "Installation prefix") do |val|
          installer.install_prefix = val
        end

        opts.on("--no-test", "Do not run tests") do |val|
          installer.install_no_test = true
        end
      end

      #if task == 'test'
      #  opts.separator ""
      #  opts.separator "Install options:"
      #
      #  opts.on("--runner TYPE", "Test runner (auto|console|gtk|gtk2|tk)") do |val|
      #    installer.config.testrunner = val
      #  end
      #end

      # common options
      opts.separator ""
      opts.separator "General options:"

      opts.on("-q", "--quiet", "Silence output") do |val|
        installer.quiet = val
      end

      opts.on("--verbose", "Provide verbose output") do |val|
        installer.verbose = val
      end

      opts.on("--no-write", "Do not write to disk") do |val|
        installer.no_harm = !val
      end

      opts.on("-n", "--dryrun", "Same as --no-write") do |val|
        installer.no_harm = val
      end

      # common options
      opts.separator ""
      opts.separator "Inform options:"

      # Tail options (eg. commands in option form)
      opts.on_tail("-h", "--help", "display this help information") do
        puts help
        exit
      end

      opts.on_tail("--version", "Show version") do
        puts File.basename($0) + ' v' + Setup::VERSION #Version.join('.')
        exit
      end

      opts.on_tail("--copyright", "Show copyright") do
        puts Setup::COPYRIGHT #opyright
        exit
      end

      begin
        opts.parse!(ARGV)
      rescue OptionParser::InvalidOption
        $stderr.puts $!.to_s.capitalize
        exit 1
      end

      begin
        installer.__send__("exec_#{task}")
      rescue Error
        raise if $DEBUG
        $stderr.puts $!.message
        $stderr.puts "Try 'ruby #{$0} --help' for detailed usage."
        exit 1
      end
    end

    # Generate help text
    def help
    fmt = " " * 10 + "%-10s       %s"
      commands = TASK_DESCRIPTIONS.collect do |k,d|
        (fmt % ["#{k}", d])
      end.join("\n").strip

      fmt = " " * 13 + "%-20s       %s"
      configs = ConfigTable::DESCRIPTIONS.collect do |k,t,d|
        (fmt % ["--#{k}", d])
      end.join("\n").strip

      text = <<-END
        USAGE: #{File.basename($0)} [command] [options]

        Commands:
            #{commands}

        Options for CONFIG:
               #{configs}

        Options for INSTALL:
               --prefix                   Set the install prefix

        Options in common:
            -q --quiet                    Silence output
               --verbose                  Provide verbose output
            -n --no-write                 Do not write to disk

      END
      text.gsub(/^ \ \ \ \ \ /, '')
    end

  end
end
