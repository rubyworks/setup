require 'setup/rubyver'
require 'setup/project'
require 'setup/configuration'
require 'setup/compiler'
require 'setup/installer'
#require 'setup/tester'
#require 'setup/documentor'
require 'setup/uninstaller'

module Setup

  #
  class Session
    # Session options.
    attr :options
    #
    def initialize(options={})
      @options = options
      self.io ||= StringIO.new  # log instead ?
    end

    #
    #def set(options)
    #  options.each do |k,v|
    #    send("#{k}=", v) if respond_to?("#{k}=")
    #  end
    #end

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
    def all
      config
      setup
      test
      document
      install
    end
    #
    def config
      log_header('config')
      #configuration.env_config
      configuration.save_config
      configuration.show if trace?
      io.puts("Configuration saved.") unless quiet?
      compiler.configure
    end
    # TODO: Hate the name b/c of <tt>$ setup setup</tt>. Rename to 'compile' or 'make'?
    def setup
      log_header('setup')
      abort "must setup config first" unless configuration.exist?
      compiler.compile
    end
    #
    def install
      log_header('install')
      abort "must setup config first" unless configuration.exist?
      installer.install
    end
    #
    def test
      return unless configuration.test?
      log_header('test')
      tester.test
    end
    #
    def document
      return unless configuration.document?
      log_header('document')
      documentor.document
    end
    #
    def clean
      log_header('clean')
      compiler.clean
    end
    #
    def distclean
      log_header('distclean')
      compiler.distclean
    end
    #
    def uninstall
      log_header('uninstall')
      uninstaller.uninstall
    end
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
    #
    def log_header(phase)
       return if quiet?
       #center = "            "
       #c = (center.size - phase.size) / 2
       #center[c,phase.size] = phase.to_s.upcase
       line = '- ' * 4 + ' -' * 24
       #c = (line.size - phase.size) / 2
       line[5,phase.size] = " #{phase.to_s.upcase} "
       io.puts "\n" + line + "\n"
    end
  end
end

