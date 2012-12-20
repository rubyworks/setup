module Setup

  # The Project class encapsulates information about the project/package
  # setup is handling.
  #
  # Setup.rb can use information about your project to provide additional
  # features.
  #
  # To inform Setup.rb of the project's name, version and load path
  # you can create a file in you project's root directory called `.index`.
  # This is a YAML file with minimum entries of:
  #
  #     ---
  #     name: foo
  #     version: 1.0.0
  #     paths:
  #       load: [lib]
  #
  # See [Indexer](http://github.com/rubyworks/indexer) for more information about
  # this file and how to easily maintain it.
  #
  # If a `.index` file is not found Setup.rb will look for `.setup/name`,
  # `.setup/version` and `.setup/loadpath` files for this information.
  #
  # As of v5.1.0, Setup.rb no longer recognizes the VERSION file
  #
  class Project

    # Match used to determine the root dir of a project.
    ROOT_MARKER = '{.index,setup.rb,.setup,lib/}'

    #
    def initialize
      @dotindex_file = find('.index')

      @dotindex = YAML.load_file(@dotindex_file) if @dotindex_file

      @name     = nil
      @version  = nil
      @loadpath = ['lib']

      if @dotindex
        @name     = @dotindex['name']
        @version  = @dotindex['version']
        @loadpath = (@dotindex['paths'] || {})['load']
      else
        if file = find('.setup/name')
          @name = File.read(file).strip
        end
        if file = find('.setup/version')
          @version = File.read(file).strip
        end
        if file = find('.setup/loadpath')
          @loadpath = File.read(file).strip
        end
      end
    end

    attr :dotindex

    # The name of the package, used to install docs in system doc/ruby-{name}/ location.
    attr :name

    # Current version number of project.
    attr :version

    #
    attr :loadpath

    alias load_path loadpath

    # Locate project root.
    def rootdir
      @rootdir ||= (
        root = Dir.glob(File.join(Dir.pwd, ROOT_MARKER), File::FNM_CASEFOLD).first
        if !root
          raise Error, "not a project directory"
        else
          Dir.pwd
        end
      )
    end

    # Setup.rb uses `ext/**/extconf.rb` as convention for the location of
    # compiled scripts.
    def extconfs
      @extconfs ||= Dir['ext/**/extconf.rb']
    end

    #
    def extensions
      @extensions ||= extconfs.collect{ |f| File.dirname(f) }
    end

    #
    def compiles?
      !extensions.empty?
    end

    #
    def yardopts
      Dir.glob(File.join(rootdir, '.yardopts')).first
    end

    #
    def document
      Dir.glob(File.join(rootdir, '.document')).first
    end

    # Find a file relative to project's root directory.
    def find(glob, flags=0)
      case flags
      when :casefold
        flags = File::FNM_CASEFOLD
      else
        flags = flags.to_i
      end      
      Dir.glob(File.join(rootdir, glob), flags).first
    end

  end

end
