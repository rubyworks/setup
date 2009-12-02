module Setup

  #
  FILETYPES = %w( bin lib ext data etc man doc )

  #
  INSTALL_RECORD = 'InstalledFiles'
  #INSTALL_RECORD = '.cache/setup/installedfiles'

  # Common base class for all Setup build classes.
  # 
  class Base

    #
    attr :project

    #
    attr :config

    #
    attr_accessor :trial

    #
    attr_accessor :trace

    #
    attr_accessor :quiet

    #
    attr_accessor :io

    #
    def initialize(project, configuration, options={})
      @project = project
      @config  = configuration
      options.each do |k,v|
        __send__("#{k}=", v) if respond_to?("#{k}=")
      end
    end

    #
    def trial? ; @trial ; end

    #
    def trace? ; @trace ; end

    #
    def quiet? ; @quiet ; end

    #
    def rootdir
      project.rootdir
    end

    # Shellout executation.
    def bash(*args)
      $stderr.puts args.join(' ') if trace?
      system(*args) or raise RuntimeError, "system(#{args.map{|a| a.inspect }.join(' ')}) failed"
    end

    # DEPRECATE
    alias_method :command, :bash

    # Shellout a ruby command.
    def ruby(*args)
      bash(config.rubyprog, *args)
    end

    # Ask a question of the user.
    def ask(question, answers=nil)
      $stdout.puts "#{question}"
      $stdout.puts " [#{answers}] " if answers
      until inp = $stdin.gets ; sleep 1 ; end
      inp.strip
    end

    #
    def trace_off #:yield:
      begin
        save, @trace = trace?, false
        yield
      ensure
        @trace = save
      end
    end

    # F I L E  U T I L I T I E S

    #
    def rm_f(path)
      io.puts "rm -f #{path}" if trace?
      return if trial?
      force_remove_file(path)
    end

    #
    def force_remove_file(path)
      begin
        remove_file(path)
      rescue
      end
    end

    #
    def remove_file(path)
      File.chmod 0777, path
      File.unlink path
    end

    #
    def rmdir(path)
      $stderr.puts "rmdir #{path}" if trace?
      return if trial?
      Dir.rmdir path
    end

  end

  #
  class Error < StandardError
  end

end

