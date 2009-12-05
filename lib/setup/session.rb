require 'setup/core_ext'
require 'setup/constants'
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

    #
    def force?; @options[:force]; end

    #
    def force=(val)
      @options[:force] = val
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
      config
      if configuration.compile? && project.compiles?
        make
      end
      if configuration.test?
        test
      end
      install
      #if configuration.document?
      #  document
      #end
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

    #
    def make
      abort "must setup config first" unless configuration.exist?
      log_header('Compiling')
      compiler.compile
    end

    # What #make used to be called.
    alias_method :setup, :make

    #
    def install
      abort "must setup config first" unless configuration.exist?
      log_header('Installing')
      installer.install
    end

    #
    def test
      return unless tester.testable?
      log_header('Testing')
      tester.test
    end

    #
    def document
      #return unless configuration.document?
      log_header('Documenting')
      documentor.document
    end

    #
    def clean
      log_header('Cleaning')
      compiler.clean
    end

    #
    def distclean
      log_header('Distcleaning')
      compiler.distclean
    end

    #
    def uninstall
      if !File.exist?(INSTALL_RECORD)
        io.puts "Nothing is installed."
        return
      end
      log_header('Uninstalling')
      uninstaller.uninstall
      io.puts('Ok.')
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
      if trial?
        io.puts("\n[TRIAL RUN] #{phase}...")
      else
        io.puts("\n#{phase}...")
      end
    end

    #   #center = "            "
    #   #c = (center.size - phase.size) / 2
    #   #center[c,phase.size] = phase.to_s.upcase
    #   line = '- ' * 4 + ' -' * 28
    #   #c = (line.size - phase.size) / 2
    #   line[5,phase.size] = " #{phase.to_s.upcase} "
    #   io.puts "\n" + line + "\n\n"
    #end

  end

end

