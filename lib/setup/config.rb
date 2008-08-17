require 'rbconfig'
require 'setup/rubyver'
require 'setup/error'

module Setup

  # Config stores platform information.

  class ConfigTable  # TODO: Rename to Config (?)

    RBCONFIG  = ::Config::CONFIG

    CONFIGFILE = '.config'

    DESCRIPTIONS = [
      [:prefix          , :path, 'path prefix of target environment'],
      [:bindir          , :path, 'directory for commands'],
      [:libdir          , :path, 'directory for libraries'],
      [:datadir         , :path, 'directory for shared data'],
      [:mandir          , :path, 'directory for man pages'],
      [:docdir          , :path, 'Directory for documentation'],
      [:sysconfdir      , :path, 'directory for system configuration files'],
      [:localstatedir   , :path, 'directory for local state data'],
      [:libruby         , :path, 'directory for ruby libraries'],
      [:librubyver      , :path, 'directory for standard ruby libraries'],
      [:librubyverarch  , :path, 'directory for standard ruby extensions'],
      [:siteruby        , :path, 'directory for version-independent aux ruby libraries'],
      [:siterubyver     , :path, 'directory for aux ruby libraries'],
      [:siterubyverarch , :path, 'directory for aux ruby binaries'],
      [:rbdir           , :path, 'directory for ruby scripts'],
      [:sodir           , :path, 'directory for ruby extentions'],
      [:rubypath        , :prog, 'path to set to #! line'],
      [:rubyprog        , :prog, 'ruby program using for installation'],
      [:makeprog        , :prog, 'make program to compile ruby extentions'],
      [:extconfopt      , :name, 'options to pass-thru to extconf.rb'],
      [:without_ext     , :bool, 'do not compile/install ruby extentions'],
      [:without_doc     , :bool, 'do not generate html documentation'],
      [:shebang         , :pick, 'shebang line (#!) editing mode (all,ruby,never)'],
      [:doctemplate     , :pick, 'document template to use (html|xml)'],
      [:testrunner      , :pick, 'Runner to use for testing (auto|console|tk|gtk|gtk2)'],
      [:installdirs     , :pick, 'install location mode (std,site,home :: libruby,site_ruby,$HOME)']
    ]

    # List of configurable options.
    OPTIONS = DESCRIPTIONS.collect{ |(k,t,v)| k.to_s }

    # Pathname attribute. Pathnames are automatically expanded
    # unless they start with '$', a path variable.
    def self.attr_pathname(name)
      class_eval %{
        def #{name}
          @#{name}.gsub(%r<\\$([^/]+)>){ self[$1] }
        end
        def #{name}=(path)
          raise SetupError, "bad config: #{name.to_s.upcase} requires argument" unless path
          @#{name} = (path[0,1] == '$' ? path : File.expand_path(path))
        end
      }   
    end

    # List of pathnames. These are not expanded though.
    def self.attr_pathlist(name)
      class_eval %{
        def #{name}
          @#{name}
        end
        def #{name}=(pathlist)
          case pathlist
          when Array
            @#{name} = pathlist
          else
            @#{name} = pathlist.to_s.split(/[:;,]/)
          end
        end
      }   
    end

    # Adds boolean support.
    def self.attr_accessor(*names)
      bools, attrs = names.partition{ |name| name.to_s =~ /\?$/ }
      attr_boolean *bools
      super *attrs
    end

    # Boolean attribute. Can be assigned true, false, nil, or
    # a string matching yes|true|y|t or no|false|n|f.
    def self.attr_boolean(*names)
      names.each do |name|
        name = name.to_s.chomp('?')
        attr_reader name  # MAYBE: Deprecate
        code = %{
          def #{name}?; @#{name}; end
          def #{name}=(val)
            case val
            when true, false, nil
              @#{name} = val
            else
              case val.to_s.downcase
              when 'y', 'yes', 't', 'true'
                 @#{name} = true
              when 'n', 'no', 'f', 'false'
                 @#{name} = false
              else
                raise SetupError, "bad config: use #{name.upcase}=(yes|no) [\#{val}]"
              end
            end
          end
        }
        class_eval code
      end
    end

    DESCRIPTIONS.each do |k,t,d|
      case t
      when :path
        attr_pathname k
      when :bool
        attr_boolean k
      else
        attr_accessor k
      end
    end

    # # provide verbosity (default is true)
    # attr_accessor :verbose?

    # # don't actually write files to system
    # attr_accessor :no_harm?

    # shebang has only three options.
    def shebang=(val)
      if %w(all ruby never).include?(val)
        @shebang = val
      else
        raise SetupError, "bad config: use SHEBANG=(all|ruby|never) [#{val}]"
      end
    end

    # installdirs has only three options; and it has side-effects.
    def installdirs=(val)
      @installdirs = val
      case val.to_s
      when 'std'
        self.rbdir = '$librubyver'
        self.sodir = '$librubyverarch'
      when 'site'
        self.rbdir = '$siterubyver'
        self.sodir = '$siterubyverarch'
      when 'home'
        raise SetupError, 'HOME is not set.' unless ENV['HOME']
        self.prefix = ENV['HOME']
        self.rbdir = '$libdir/ruby'
        self.sodir = '$libdir/ruby'
      else
        raise SetupError, "bad config: use INSTALLDIRS=(std|site|home|local) [#{val}]"
      end
    end

    # New ConfigTable
    def initialize(values=nil)
      initialize_defaults
      if values
        values.each{ |k,v| __send__("#{k}=", v) }
      end
      yeild(self) if block_given?
      load_config if File.file?(CONFIGFILE)
    end

    # Assign CONFIG defaults
    #
    # TODO: Does this handle 'nmake' on windows?
    def initialize_defaults
      prefix = RBCONFIG['prefix']

      rubypath = File.join(RBCONFIG['bindir'], RBCONFIG['ruby_install_name'] + RBCONFIG['EXEEXT'])

      major = RBCONFIG['MAJOR'].to_i
      minor = RBCONFIG['MINOR'].to_i
      teeny = RBCONFIG['TEENY'].to_i
      version = "#{major}.#{minor}"

      # ruby ver. >= 1.4.4?
      newpath_p = ((major >= 2) or
                   ((major == 1) and
                    ((minor >= 5) or
                     ((minor == 4) and (teeny >= 4)))))

      if RBCONFIG['rubylibdir']
        # V > 1.6.3
        libruby         = "#{prefix}/lib/ruby"
        librubyver      = RBCONFIG['rubylibdir']
        librubyverarch  = RBCONFIG['archdir']
        siteruby        = RBCONFIG['sitedir']
        siterubyver     = RBCONFIG['sitelibdir']
        siterubyverarch = RBCONFIG['sitearchdir']
      elsif newpath_p
        # 1.4.4 <= V <= 1.6.3
        libruby         = "#{prefix}/lib/ruby"
        librubyver      = "#{prefix}/lib/ruby/#{version}"
        librubyverarch  = "#{prefix}/lib/ruby/#{version}/#{c['arch']}"
        siteruby        = RBCONFIG['sitedir']
        siterubyver     = "$siteruby/#{version}"
        siterubyverarch = "$siterubyver/#{RBCONFIG['arch']}"
      else
        # V < 1.4.4
        libruby         = "#{prefix}/lib/ruby"
        librubyver      = "#{prefix}/lib/ruby/#{version}"
        librubyverarch  = "#{prefix}/lib/ruby/#{version}/#{c['arch']}"
        siteruby        = "#{prefix}/lib/ruby/#{version}/site_ruby"
        siterubyver     = siteruby
        siterubyverarch = "$siterubyver/#{RBCONFIG['arch']}"
      end

      if arg = RBCONFIG['configure_args'].split.detect {|arg| /--with-make-prog=/ =~ arg }
        makeprog = arg.sub(/'/, '').split(/=/, 2)[1]
      else
        makeprog = 'make'
      end

      parameterize = lambda do |path|
        val = RBCONFIG[path]
        raise "Unknown path -- #{path}" if val.nil?
        val.sub(/\A#{Regexp.quote(prefix)}/, '$prefix')
      end

      self.prefix          = prefix
      self.bindir          = parameterize['bindir']
      self.libdir          = parameterize['libdir']
      self.datadir         = parameterize['datadir']
      self.mandir          = parameterize['mandir']
      self.docdir          = File.dirname(parameterize['docdir'])  # b/c of trailing $(PACKAGE)
      self.sysconfdir      = parameterize['sysconfdir']
      self.localstatedir   = parameterize['localstatedir']
      self.libruby         = libruby
      self.librubyver      = librubyver
      self.librubyverarch  = librubyverarch
      self.siteruby        = siteruby
      self.siterubyver     = siterubyver
      self.siterubyverarch = siterubyverarch
      self.rbdir           = '$siterubyver'
      self.sodir           = '$siterubyverarch'
      self.rubypath        = rubypath
      self.rubyprog        = rubypath
      self.makeprog        = makeprog
      self.extconfopt      = ''
      self.shebang         = 'ruby'
      self.without_ext     = 'no'
      self.without_doc     = 'yes'
      self.doctemplate     = 'html'
      self.testrunner      = 'auto'
      self.installdirs     = 'site'
    end

    # Get configuration from environment.
    def env_config
      OPTIONS.each do |name|
        if value = ENV[name]
          __send__("#{name}=",value)
        end
      end
    end

    # Load configuration.
    def load_config
      #if File.file?(CONFIGFILE)
        begin
          File.foreach(CONFIGFILE) do |line|
            k, v = *line.split(/=/, 2)
            k.gsub!('-','_')
            __send__("#{k}=",v.strip) #self[k] = v.strip
          end
        rescue Errno::ENOENT
          raise SetupError, $!.message + "\n#{File.basename($0)} config first"
        end
      #end
    end

    # Save configuration.
    def save_config
      File.open(CONFIGFILE, 'w') do |f|
        OPTIONS.each do |name|
          val = self[name]
          f << "#{name}=#{val}\n"
        end
      end
    end

    def show
      fmt = "%-20s %s\n"
      OPTIONS.each do |name|
        value = self[name]
        reslv = __send__(name)
        case reslv
        when String
          reslv = "(none)" if reslv.empty?
        when false, nil
          reslv = "no"
        when true
          reslv = "yes"
        end
        printf fmt, name, reslv
      end
    end

    #

    def extconfs
      @extconfs ||= Dir['ext/**/extconf.rb']
    end

    def extensions
      @extensions ||= extconfs.collect{ |f| File.dirname(f) }
    end

    def compiles?
      !extensions.empty?
    end

    private

    # Get unresloved attribute.
    def [](name)
      instance_variable_get("@#{name}")
    end

    # Set attribute.
    def []=(name, value)
      instance_variable_set("@#{name}", value)
    end

    # Resolved attribute. (for paths)
    #def resolve(name)
    #  self[name].gsub(%r<\\$([^/]+)>){ self[$1] }
    #end

  end

end

