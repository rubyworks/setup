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

    # Run all tasks in sequence.
    #
    # * config
    # * make
    # * test      (if selected)
    # * install
    # * document  (if selected)
    #
    # Note that ri documentation is not easy to uninstall.
    # So use the --ri option knowledgably. You can alwasy
    # Use <tt>setup.rb document</tt> at a later time.
    #
    def all
      config
      if configuration.compile? && project.compiles?
        make
      end
      if configuration.test?
        ok = test
        exit 1 unless ok
      end
      install
      if configuration.ri?
        document
      end
    end

    #
    def config
      log_header('Configure')
      if configuration.save_config
        io.puts "Configuration saved." unless quiet?
      else
        io.puts "Configuration current." unless quiet?
      end
      puts configuration if trace? && !quiet?
      if compiler.compiles?
        compiler.configure
      end
    end

    #
    def make
      abort "must setup config first" unless configuration.exist?
      log_header('Compile')
      compiler.compile
    end

    # What #make used to be called.
    alias_method :setup, :make

    #
    def install
      abort "must setup config first" unless configuration.exist?
      log_header('Install')
      installer.install
    end

    #
    def test
      return true unless tester.testable?
      log_header('Test')
      tester.test
    end

    #
    def document
      #return unless configuration.doc?
      log_header('Document')
      documentor.document
    end

    #
    def clean
      log_header('Clean')
      compiler.clean
    end

    #
    def distclean
      log_header('Distclean')
      compiler.distclean
    end

    #
    def uninstall
      if !File.exist?(INSTALL_RECORD)
        io.puts "Nothing is installed."
        return
      end
      log_header('Uninstall')
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
        str = "#{phase.upcase} (trail run)"
      else
        str = "#{phase.upcase}"
      end
      line = "- " * 35
      line[0..str.size+3] = str
      io.puts("\n- - #{line}\n\n")
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

