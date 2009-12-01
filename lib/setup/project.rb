module Setup

  # The Project class encapsulates information
  # about the project/package setup is effecting.

  class Project

    # Match used to determine the root dir of a project.
    ROOT_MARKER = '{setup.rb,script/setup,meta/,MANIFEST,lib/}'

    # TODO: locate project root via some marker
    def rootdir
      @rootdir ||= (
        root = Dir[File.join(Dir.pwd, ROOT_MARKER)].first
        if !root
          raise Error, "not a project directory"
        else
          Dir.pwd
        end
      )
    end

    # The name of the package, used to install docs in system doc/ruby-{name}/ location.
    # The information must be provided in a file called meta/package.
    def name
      @name = (
        if file = Dir["{script/setup,meta,.meta}/name"].first
          File.read(file).strip
        else
          nil
        end
      )
    end

    # This is needed if a project has loadpaths other than the standard lib/.
    # Note the routine is designed to handle YAML arrays or line by line list.
    def loadpath
      @loadpath ||= (
        if file = Dir.glob('{script/setup,meta,.meta}/loadpath').first
          raw = File.read(file).strip.chomp(']')
          raw.split(/[\n,]/).map do |e|
            e.strip.sub(/^[\[-]\s*/,'')
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

