module Setup

  # The Project class encapsulates information
  # about the project/package setup is effecting.
  #
  # This class recognizes the VERSION file as defined by
  # Ruby POM, but will fallback to .setup/name, .setup/version
  # and .setup/loadpath if a VERSION file is not found or
  # can not be parsed.
  class Project

    # Match used to determine the root dir of a project.
    ROOT_MARKER = '{setup.rb,.setup,VERSION*,MANIFEST,lib/}'

    #
    def initialize
      parse_verfile
    end

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

    # Path to VERSION file.
    def verfile
      @verfile ||= Dir.glob(File.join(rootdir, 'version{,.txt,.yml,.yaml}'), File::FNM_CASEFOLD).first
    end

    # Parse VERSION file accoring to Ruby POM standard.
    def parse_verfile
      if verfile
        data = YAML.load(File.new(verfile))
        case data
        when Hash
          data = data.inject({}){ |h,(k,v)| h[k.to_s] = v; h }
          @name     = data['name']
          @loadpath = data['path']
          @version  = data.values_at('major', 'minor', 'patch', 'state', 'build').compact.join('.')
        when String
          data.strip!
          if md = /^(\w+)[-\ ]/.match(data)
            @name = md[1]
          end
          if md = /\ (\d+[.].*?)\ /.match(data)
            @version = md[1]
          end
          @loadpath = []
          data.scan(/\ (\S+\/)\ /).each do |path|
            @loadpath << path.chomp('/')
          end
          @loadpath = nil if @loadpath.empty?
        else
          $stderr << "warn: bad #{file} ?"
        end
      end
    end

    # The name of the package, used to install docs in system doc/ruby-{name}/ location.
    def name
      @name = (
        if file = Dir[".setup/name"].first
          File.read(file).strip
        else
          nil
        end
      )
    end

    # Current version number of project.
    def version
      @version = (
        if file = Dir[".setup/version"].first
          File.read(file).strip
        else
          nil
        end
      )
    end

    # This is needed if a project has loadpaths other than the standard lib/.
    # Note the routine is designed to handle (pseudo) YAML arrays or line by
    # line list.
    def loadpath
      @loadpath ||= (
        if file = Dir.glob('.script/loadpath').first
          data = YAML.load(File.new(file))
          case data
          when String
            data.split(/\n/).map{|e| e.strip}
          when Array
            data
          else
            nil
          end
        else
          nil
        end
      )
    end

    #
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

  end

end

