require 'rbconfig'
require 'fileutils'
require 'erb'
require 'yaml'
require 'setup/rubyver'

module Setup

  # Stores platform information and general install settings.

  class Configuration

    RBCONFIG  = ::Config::CONFIG

    #CONFIGFILE = '.cache/setup/config'
    CONFIGFILE = 'SetupConfig'

    # Custom configuration file.
    METACONFIGFILE = 'script/.setup/metaconfig{,.rb}'

    def self.options
      @options ||= []
    end

    # TODO: better methods for path type
    def self.option(name, type, description)
      options << [name.to_s, type, description]
      attr_accessor(name)
    end

    option :prefix          , :path, 'path prefix of target environment'
    option :bindir          , :path, 'directory for commands'
    option :libdir          , :path, 'directory for libraries'
    option :datadir         , :path, 'directory for shared data'
    option :mandir          , :path, 'directory for man pages'
    option :docdir          , :path, 'directory for documentation'
    option :rbdir           , :path, 'directory for ruby scripts'
    option :sodir           , :path, 'directory for ruby extentions'
    option :sysconfdir      , :path, 'directory for system configuration files'
    option :localstatedir   , :path, 'directory for local state data'

    option :libruby         , :path, 'directory for ruby libraries'
    option :librubyver      , :path, 'directory for standard ruby libraries'
    option :librubyverarch  , :path, 'directory for standard ruby extensions'
    option :siteruby        , :path, 'directory for version-independent aux ruby libraries'
    option :siterubyver     , :path, 'directory for aux ruby libraries'
    option :siterubyverarch , :path, 'directory for aux ruby binaries'

    option :rubypath        , :prog, 'path to set to #! line'
    option :rubyprog        , :prog, 'ruby program used for installation'
    option :makeprog        , :prog, 'make program to compile ruby extentions'

    option :extconfopt      , :opts, 'options to pass-thru to extconf.rb'

    option :shebang         , :pick, 'shebang line (#!) editing mode (all,ruby,never)'

    option :no_ext          , :bool, 'do not compile/install ruby extentions'
    option :no_test         , :bool, 'do not run tests'
    option :no_doc          , :bool, 'do not generate ri documentation'

    #option :rdoc            , :pick, 'generate rdoc documentation'
    #option :rdoc_template   , :pick, 'rdoc document template to use'
    #option :testrunner      , :pick, 'Runner to use for testing (auto|console|tk|gtk|gtk2)'

    option :install_prefix  , :path, 'install to alternate root location'
    option :root            , :path, 'install to alternate root location'

    option :installdirs     , :pick, 'install location mode (site,std,home)'  #, local)
    option :type            , :pick, 'install location mode (site,std,home)'

    # Turn all of CONFIG into methods.

    ::Config::CONFIG.each do |key,val|
      next if key == "configure_args"
      name = key.to_s.downcase
      #name = name.sub(/^--/,'')
      #name = name.gsub(/-/,'_')
      define_method(name){ val }
    end

    # Turn all of CONFIG["configure_args"] into methods.

    ::Config::CONFIG["configure_args"].each do |ent|
      key, val = *ent.split("=")
      name = key.downcase
      name = name.sub(/^--/,'')
      name = name.gsub(/-/,'_')
      define_method(name){ val }
    end

    #
    def options
      #(class << self ; self ; end).options
      self.class.options
    end

    # #  I N I T I A L I Z E  # #

    # New ConfigTable
    def initialize(values={})
      initialize_metaconfig
      initialize_defaults
      initialize_environment
      initialize_configfile

      values.each{ |k,v| __send__("#{k}=", v) }
      yeild(self) if block_given?
    end

    #
    def initialize_metaconfig
      if File.exist?(METACONFIGFILE)
        script = File.read(METACONFIGFILE)
        (class << self; self; end).class_eval(script)
      end
    end

    # By default installation is to site locations,
    # and ri documentation will not be generated.
    def initialize_defaults
      self.type    = 'site'
      self.no_doc  = true
      self.no_test = false
      self.no_ext  = false
      #@rbdir = siterubyver      #'$siterubyver'
      #@sodir = siterubyverarch  #'$siterubyverarch'
    end

    # Get configuration from environment.
    def initialize_environment
      options.each do |name, type, description|
        if value = ENV["RUBYSETUP_#{name.to_s.upcase}"]
          __send__("#{name}=",value)
        end
      end
    end

    # Load configuration.
    def initialize_configfile
      if File.exist?(CONFIGFILE)
        erb = ERB.new(File.read(CONFIGFILE))
        txt = erb.result(binding)
        dat = YAML.load(txt)
        dat.each do |k, v|
          next if 'type' == k
          next if 'installdirs' == k
          k = k.gsub('-','_')
          __send__("#{k}=", v)
        end

        if dat['type']
          self.type = dat['type']
        end

        if dat['installdirs']
          self.installdirs = dat['installdirs']
        end
      #else
      #  raise Error, $!.message + "\n#{File.basename($0)} config first"
      end
    end

    #def initialize_configfile
    # begin
    #    File.foreach(CONFIGFILE) do |line|
    #      k, v = *line.split(/=/, 2)
    #      k.gsub!('-','_')
    #      __send__("#{k}=",v.strip) #self[k] = v.strip
    #    end
    #  rescue Errno::ENOENT
    #    raise Error, $!.message + "\n#{File.basename($0)} config first"
    #  end
    #end

    # #  B A S E  D I R E C T O R I E S  # #

    #
    #def base_libruby
    #  "lib/ruby"
    #end

    # Base bin directory
    def base_bindir
      @base_bindir ||= subprefix('bindir')
    end

    # Base libdir
    def base_libdir
      @base_libdir ||= subprefix('libdir')
    end

    #
    def base_datadir
      @base_datadir ||= subprefix('datadir')
    end

    #
    def base_mandir
      @base_mandir ||= subprefix('mandir')
    end

    # NOTE: This removed the trailing <tt>$(PACKAGE)</tt>.
    def base_docdir
      @base_docdir || File.dirname(subprefix('docdir'))
    end

    #
    def base_rubylibdir
      @rubylibdir ||= subprefix('rubylibdir')
    end

    #
    def base_rubyarchdir
      @base_rubyarchdir ||= subprefix('archdir')
    end

    # Base directory for system configuration files
    def base_sysconfdir
      @base_sysconfdir ||= subprefix('sysconfdir')
    end

    # Base directory for local state data
    def base_localstatedir
      @base_localstatedir ||= subprefix('localstatedir')
    end


    # #  C O N F I G U R A T I O N  # #

    #
    def type
      @type ||= 'site'
    end

    #
    def type=(val)
      @type = val
      case val.to_s
      when 'std', 'ruby'
        @rbdir = librubyver       #'$librubyver'
        @sodir = librubyverarch   #'$librubyverarch'
      when 'site'
        @rbdir = siterubyver      #'$siterubyver'
        @sodir = siterubyverarch  #'$siterubyverarch'
      when 'home'
        self.prefix = File.join(home, '.local')  # TODO: Use XDG
        @rbdir = nil #'$libdir/ruby'
        @sodir = nil #'$libdir/ruby'
      #when 'local'
      #  rbdir = subprefix(librubyver, '')
      #  sodir = subprefix(librubyverarch, '')
      #  self.prefix = '/usr/local' # FIXME: how?
      #  self.rbdir  = File.join(prefix, rbdir) #'$libdir/ruby'
      #  self.sodir  = File.join(prefix, sodir) #'$libdir/ruby'
      else
        raise Error, "bad config: use type=(std|site|home) [#{val}]"
      end
    end

    #
    alias_method :installdirs, :type

    #
    alias_method :installdirs=, :type=


    #
    alias_method :install_prefix, :root

    #
    alias_method :install_prefix=, :root=


    # Path prefix of target environment
    def prefix
      @prefix ||= RBCONFIG['prefix']
    end

    # Set path prefix of target environment
    def prefix=(path)
      @prefix = pathname(path)
    end

    # Directory for ruby libraries
    def libruby
      @libruby ||= RBCONFIG['prefix'] + "/lib/ruby"
    end

    # Set directory for ruby libraries
    def libruby=(path)
      path = pathname(path)
      @librubyver = librubyver.sub(libruby, path)
      @librubyverarch = librubyverarch.sub(libruby, path)
      @libruby = path
    end

    # Directory for standard ruby libraries
    def librubyver
      @librubyver ||= RBCONFIG['rubylibdir']
    end

    # Set directory for standard ruby libraries
    def librubyver=(path)
      @librubyver = pathname(path)
    end

    # Directory for standard ruby extensions
    def librubyverarch
      @librubyverarch ||= RBCONFIG['archdir']
    end

    # Set directory for standard ruby extensions
    def librubyverarch=(path)
      @librubyverarch = pathname(path)
    end

    # Directory for version-independent aux ruby libraries
    def siteruby
      @siteruby ||= RBCONFIG['sitedir']
    end

    # Set directory for version-independent aux ruby libraries
    def siteruby=(path)
      path = pathname(path)
      @siterubyver = siterubyver.sub(siteruby, path)
      @siterubyverarch = siterubyverarch.sub(siteruby, path)
      @siteruby = path
    end

    # Directory for aux ruby libraries
    def siterubyver
      @siterubyver ||= RBCONFIG['sitelibdir']
    end

    # Set directory for aux ruby libraries
    def siterubyver=(path)
      @siterubyver = pathname(path)
    end

    # Directory for aux ruby binary libraries
    def siterubyverarch
      @siterubyverarch ||= RBCONFIG['sitearchdir']
    end

    # Set directory for aux arch ruby binaries
    def siterubyverarch=(path)
      @siterubyverarch = pathname(path)
    end

    # Directory for commands
    def bindir
      @bindir || File.join(prefix, base_bindir)
    end

    # Set directory for commands
    def bindir=(path)
      @bindir = pathname(path)
    end

    # Directory for libraries
    def libdir
      @libdir || File.join(prefix, base_libdir)
    end

    # Set directory for libraries
    def libdir=(path)
      @libdir = pathname(path)
    end

    # Directory for shared data
    def datadir
      @datadir || File.join(prefix, base_datadir)
    end

    # Set directory for shared data
    def datadir=(path)
      @datadir = pathname(path)
    end

    # Directory for man pages
    def mandir
      @mandir || File.join(prefix,  base_mandir)
    end

    # Set directory for man pages
    def mandir=(path)
      @mandir = pathname(path)
    end

    # Directory for documentation
    def docdir
      @docdir || File.join(prefix, base_docdir)
    end

    # Set directory for documentation
    def docdir=(path)
      @docdir = pathname(path)
    end

    # Directory for ruby scripts
    def rbdir
      @rbdir || File.join(prefix, base_rubylibdir)
    end

    # Directory for ruby extentions
    def sodir
      @sodir || File.join(prefix, base_rubyarchdir)
    end

    # Directory for system configuration files
    # TODO: Can this be prefixed?
    def sysconfdir
      @sysconfdir ||= base_sysconfdir
    end

    # Set directory for system configuration files
    def sysconfdir=(path)
      @sysconfdir = pathname(path)
    end

    # Directory for local state data
    # TODO: Can this be prefixed?
    def localstatedir
      @localstatedir ||= base_localstatedir
    end

    # Set directory for local state data
    def localstatedir=(path)
      @localstatedir = pathname(path)
    end

    #
    def rubypath
      #@rubypath ||= RBCONFIG['libexecdir']
      @rubypath ||= File.join(RBCONFIG['bindir'], RBCONFIG['ruby_install_name'] + RBCONFIG['EXEEXT'])
    end

    #
    def rubypath=(path)
      @rubypath = pathname(path)
    end

    #
    def rubyprog
      @rubyprog || rubypath
    end

    #
    def rubyprog=(command)
      @rubyprog = command
    end

    # TODO: Does this handle 'nmake' on windows?
    def makeprog
      @makeprog ||= (
        if arg = RBCONFIG['configure_args'].split.detect {|arg| /--with-make-prog=/ =~ arg }
          arg.sub(/'/, '').split(/=/, 2)[1]
        else
          'make'
        end
      )
    end

    #
    def makeprog=(command)
      @makeprog = command
    end

    #
    def extconfopt
      @extconfopt ||= ''
    end

    #
    def extconfopt=(string)
      @extconfopt = string
    end

    # Default is +ruby+.
    def shebang
      @shebang ||= 'ruby'
    end

    # There are three options: +all+, +ruby+, +never+.
    def shebang=(val)
      if %w(all ruby never).include?(val)
        @shebang = val
      else
        raise Error, "bad config: use SHEBANG=(all|ruby|never) [#{val}]"
      end
    end

    # 
    def no_ext
      @no_ext
    end

    #
    def no_ext=(val)
      @no_ext = boolean(val)
    end

    #
    def no_test
      @no_test
    end

    #
    def no_test=(val)
      @no_test = boolean(val)
    end

    #
    def no_doc
      @no_doc
    end

    #
    def no_doc=(val)
      @no_doc = boolean(val)
    end

    #def rdoc            = 'no'
    #def rdoctemplate    = nil
    #def testrunner      = 'auto' # needed?

    def compile?
      !no_ext
    end

    def test?
      !no_test
    end

    def document?
      !no_doc
    end


    # #  C O N V E R S I O N  # #

    #
    def to_h
      h = {}
      self.class.options.each do |name, type, description|
        h[name] = __send__(name)
      end
      h
    end

    #
    def to_s
      to_yaml.sub(/\A---\s*\n/,'')
    end

    #
    def to_yaml(*args)
      to_h.to_yaml(*args)
    end

    # Save configuration.
    def save_config
      out = to_yaml
      if not File.exist?(File.dirname(CONFIGFILE))
        FileUtils.mkdir_p(File.dirname(CONFIGFILE))
      end
      if File.exist?(CONFIGFILE)
        txt = File.read(CONFIGFILE)
        return nil if txt == out
      end          
      File.open(CONFIGFILE, 'w'){ |f| f << out }
      true
    end

    # Does the configuration file exist?
    def exist?
      File.exist?(CONFIGFILE)
    end

    #
    #def show
    #  fmt = "%-20s %s\n"
    #  OPTIONS.each do |name|
    #    value = self[name]
    #    reslv = __send__(name)
    #    case reslv
    #    when String
    #      reslv = "(none)" if reslv.empty?
    #    when false, nil
    #      reslv = "no"
    #    when true
    #      reslv = "yes"
    #    end
    #    printf fmt, name, reslv
    #  end
    #end

  private

    def pathname(path)
      path.gsub(%r<\\$([^/]+)>){ self[$1] }
    end

    #def absolute_pathname(path)
    #  File.expand_path(path).gsub(%r<\\$([^/]+)>){ self[$1] }
    #end

    # Boolean attribute. Can be assigned true, false, nil, or
    # a string matching yes|true|y|t or no|false|n|f.
    def boolean(val, name=nil)
      case val
      when true, false, nil
        val
      else
        case val.to_s.downcase
        when 'y', 'yes', 't', 'true'
           true
        when 'n', 'no', 'f', 'false'
           false
        else
          raise Error, "bad config: use --#{name}=(yes|no) [\#{val}]"
        end
      end
    end

    #
    def subprefix(path, with='')
      val = RBCONFIG[path]
      raise "Unknown path -- #{path}" if val.nil?
      prefix = Regexp.quote(RBCONFIG['prefix'])
      val.sub(/\A#{prefix}/, with)
    end

    #
    def home
      ENV['HOME'] || raise(Error, 'HOME is not set.')
    end

    # Get unresloved attribute.
    #def [](name)
    #  instance_variable_get("@#{name}")
    #end

    # Set attribute.
    #def []=(name, value)
    #  instance_variable_set("@#{name}", value)
    #end

    # Resolved attribute. (for paths)
    #def resolve(name)
    #  self[name].gsub(%r<\\$([^/]+)>){ self[$1] }
    #end

  end #class ConfigTable

end #module Setup








    # Pathname attribute. Pathnames are automatically expanded
    # unless they start with '$', a path variable.
    #def self.attr_pathname(name)
    #  class_eval %{
    #    def #{name}
    #      @#{name}.gsub(%r<\\$([^/]+)>){ self[$1] }
    #    end
    #    def #{name}=(path)
    #      raise Error, "bad config: #{name.to_s.upcase} requires argument" unless path
    #      @#{name} = (path[0,1] == '$' ? path : File.expand_path(path))
    #    end
    #  }
    #end

    # List of pathnames. These are not expanded though.
    #def self.attr_pathlist(name)
    #  class_eval %{
    #    def #{name}
    #      @#{name}
    #    end
    #    def #{name}=(pathlist)
    #      case pathlist
    #      when Array
    #        @#{name} = pathlist
    #      else
    #        @#{name} = pathlist.to_s.split(/[:;,]/)
    #      end
    #    end
    #  }
    #end

    # Adds boolean support.
    #def self.attr_accessor(*names)
    #  bools, attrs = names.partition{ |name| name.to_s =~ /\?$/ }
    #  attr_boolean *bools
    #  super *attrs
    #end


    # # provide verbosity (default is true)
    # attr_accessor :verbose?

    # # don't actually write files to system
    # attr_accessor :no_harm?

=begin
    # Metaconfig file is '.config/setup/metaconfig{,.rb}'.
    def inintialize_metaconfig
      path = Dir.glob(METACONFIG_FILE).first
      if path && File.file?(path)
        MetaConfigEnvironment.new(self).instance_eval(File.read(path), path)
      end
    end

    #= Meta Configuration
    # This works a bit differently from 3.4.1.
    # Defaults are currently not supported but remain in the method interfaces.
    class MetaConfigEnvironment
      def initialize(config) #, installer)
        @config    = config
        #@installer = installer
      end

      #
      def config_names
        @config.descriptions.collect{ |n, t, d| n.to_s }
      end

      #
      def config?(name)
        @config.descriptions.find do |sym, type, desc|
          sym.to_s == name.to_s
        end
      end

      #
      def bool_config?(name)
        @config.descriptions.find do |sym, type, desc|
          sym.to_s == name.to_s && type == :bool
        end
        #@config.lookup(name).config_type == 'bool'
      end

      #
      def path_config?(name)
        @config.descriptions.find do |sym, type, desc|
          sym.to_s == name.to_s && type == :path
        end
        #@config.lookup(name).config_type == 'path'
      end

      #
      def value_config?(name)
        @config.descriptions.find do |sym, type, desc|
          sym.to_s == name.to_s && type != :prog
        end
        #@config.lookup(name).config_type != 'exec'
      end

      #
      def add_config(name, default, desc)
        @config.descriptions << [name.to_sym, nil, desc]
        #@config.add item
      end

      #
      def add_bool_config(name, default, desc)
        @config.descriptions << [name.to_sym, :bool, desc]
        #@config.add BoolItem.new(name, 'yes/no', default ? 'yes' : 'no', desc)
      end

      #
      def add_path_config(name, default, desc)
        @config.descriptions << [name.to_sym, :path, desc]
        #@config.add PathItem.new(name, 'path', default, desc)
      end

      #
      def set_config_default(name, default)
        @config[name] = default
      end

      #
      def remove_config(name)
        item = @config.descriptions.find do |sym, type, desc|
          sym.to_s == name.to_s
        end
        index = @config.descriptions.index(item)
        @config.descriptions.delete(index)
        #@config.remove(name)
      end
    end
=end

# Designed to work with Ruby 1.6.3 or greater.

