require 'setup/core_ext'
require 'setup/constats'
require 'setup/project'
require 'setup/configuration'
require 'setup/compiler'
require 'setup/installer'
require 'setup/tester'
require 'setup/documentor'
require 'setup/uninstaller'

module Setup

  #
  class Session

    # Session options.
    attr :options

    # New Session
    def initialize(options={})
      @options = options
      self.io ||= StringIO.new  # log instead ?
    end

    # #  O P T I O N S  # #

    #
    def io
      @options[:io]
    end

    #
    def io=(anyio)
      @options[:io] = anyio
    end

    #
    def trace?; @options[:trace]; end

    #
    def trace=(val)
      @options[:trace] = val
    end

    #
    def trial?; @options[:trial]; end

    #
    def trial=(val)
      @options[:trial] = val
    end

    #
    def quiet?; @options[:quiet]; end

    #
    def quiet=(val)
      @options[:quiet] = val
    end

    # #  S E T U P  T A S K S  # #

    # Run all tasks in sequences.
    #
    # * config
    # * setup
    # * test
    # * install
    # * document
    #
    def all
      log_header('config')
      config

      if configuration.compile? && project.compiles?
        log_header('setup')
        setup
      end

      if configuration.test?
        log_header('test')
        test
      end

      log_header('install')
      install

      if configuration.document?
        log_header('document')
        document
      end
    end

    # Run main set of tasks in sequences.
    #
    # * config
    # * setup
    # * install
    #
    def main
      log_header('config')
      config

      if configuration.compile? && project.compiles?
        log_header('setup')
        setup
      end

      log_header('install')
      install
    end

    #
    def config
      if configuration.save_config
        io.puts "Configuration saved." unless quiet?
      else
        io.puts "Configuration current." unless quiet?
      end
      puts configuration if trace? && !quiet?
      #io.puts("Configuration saved.") unless quiet?
      compiler.configure
    end

    # TODO: Hate the name b/c of <tt>$ setup.rb setup</tt>. Rename to 'compile' or 'make'?
    def setup
      abort "must setup config first" unless configuration.exist?
      compiler.compile
    end

    #
    def install
      abort "must setup config first" unless configuration.exist?
      installer.install
    end

    #
    def test
      return unless tester.testable?
      tester.test
    end

    #
    def document
      documentor.document
    end

    #
    def clean
      #log_header('clean')
      compiler.clean
    end

    #
    def distclean
      #log_header('distclean')
      compiler.distclean
    end

    #
    def uninstall
      #log_header('uninstall')
      uninstaller.uninstall
    end

    #
    def show
      #configuration.show
      puts configuration
    end

    # #  C O N T R O L L E R S / M O D E L S  # #

    #
    def project
      @project ||= Project.new
    end
    #
    def configuration
      @configuration ||= Configuration.new
    end
    #
    def compiler
      @compiler ||= Compiler.new(project, configuration, options)
    end
    #
    def installer
      @installer ||= Installer.new(project, configuration, options)
    end
    #
    def tester
      @tester ||= Tester.new(project, configuration, options)
    end
    #
    def documentor
      @documentor ||= Documentor.new(project, configuration, options)
    end
    #
    def uninstaller
      @uninstaller ||= Uninstaller.new(project, configuration, options)
    end

    # #  S U P P O R T  # #
  
    #
    def log_header(phase)
       return if quiet?
       #center = "            "
       #c = (center.size - phase.size) / 2
       #center[c,phase.size] = phase.to_s.upcase
       line = '- ' * 4 + ' -' * 28
       #c = (line.size - phase.size) / 2
       line[5,phase.size] = " #{phase.to_s.upcase} "
       io.puts "\n" + line + "\n\n"
    end

  end

end

