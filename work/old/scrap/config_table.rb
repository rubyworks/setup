class ConfigTable

  include Enumerable

  def initialize(rbconfig)
    @rbconfig = rbconfig
    @items = []
    @table = {}
    # options
    @install_prefix = nil
    @config_opt = nil
    @verbose = true
    @no_harm = false
  end

  attr_accessor :install_prefix
  attr_accessor :config_opt

  def [](key)
    lookup(key).resolve(self)
  end

  def []=(key, val)
    lookup(key).set val
  end

  def names
    @items.map {|i| i.name }
  end

  def each(&block)
    @items.each(&block)
  end

  def key?(name)
    @table.key?(name)
  end

  def lookup(name)
    @table[name] or setup_rb_error "no such config item: #{name}"
  end

  def add(item)
    @items.push item
    @table[item.name] = item
  end

  def remove(name)
    item = lookup(name)
    @items.delete_if {|i| i.name == name }
    @table.delete_if {|name, i| i.name == name }
    item
  end

  def load_script(path, inst = nil)
    if File.file?(path)
      MetaConfigEnvironment.new(self, inst).instance_eval File.read(path), path
    end
  end

  def savefile
    '.config'
  end

  def load_savefile
    begin
      File.foreach(savefile()) do |line|
        k, v = *line.split(/=/, 2)
        self[k] = v.strip
      end
    rescue Errno::ENOENT
      setup_rb_error $!.message + "\n#{File.basename($0)} config first"
    end
  end

  def save
    @items.each {|i| i.value }
    File.open(savefile(), 'w') {|f|
      @items.each do |i|
        f.printf "%s=%s\n", i.name, i.value if i.value? and i.value
      end
    }
  end

  def load_standard_entries
    standard_entries(@rbconfig).each do |ent|
      add ent
    end
  end

  def standard_entries(rbconfig)
    c = rbconfig

    rubypath = File.join(c['bindir'], c['ruby_install_name'] + c['EXEEXT'])

    major = c['MAJOR'].to_i
    minor = c['MINOR'].to_i
    teeny = c['TEENY'].to_i
    version = "#{major}.#{minor}"

    # ruby ver. >= 1.4.4?
    newpath_p = ((major >= 2) or
                 ((major == 1) and
                  ((minor >= 5) or
                   ((minor == 4) and (teeny >= 4)))))

    if c['rubylibdir']
      # V > 1.6.3
      libruby         = "#{c['prefix']}/lib/ruby"
      librubyver      = c['rubylibdir']
      librubyverarch  = c['archdir']
      siteruby        = c['sitedir']
      siterubyver     = c['sitelibdir']
      siterubyverarch = c['sitearchdir']
    elsif newpath_p
      # 1.4.4 <= V <= 1.6.3
      libruby         = "#{c['prefix']}/lib/ruby"
      librubyver      = "#{c['prefix']}/lib/ruby/#{version}"
      librubyverarch  = "#{c['prefix']}/lib/ruby/#{version}/#{c['arch']}"
      siteruby        = c['sitedir']
      siterubyver     = "$siteruby/#{version}"
      siterubyverarch = "$siterubyver/#{c['arch']}"
    else
      # V < 1.4.4
      libruby         = "#{c['prefix']}/lib/ruby"
      librubyver      = "#{c['prefix']}/lib/ruby/#{version}"
      librubyverarch  = "#{c['prefix']}/lib/ruby/#{version}/#{c['arch']}"
      siteruby        = "#{c['prefix']}/lib/ruby/#{version}/site_ruby"
      siterubyver     = siteruby
      siterubyverarch = "$siterubyver/#{c['arch']}"
    end

    parameterize = lambda {|path|
      path.sub(/\A#{Regexp.quote(c['prefix'])}/, '$prefix')
    }

    if arg = c['configure_args'].split.detect {|arg| /--with-make-prog=/ =~ arg }
      makeprog = arg.sub(/'/, '').split(/=/, 2)[1]
    else
      makeprog = 'make'
    end

    [
      ExecItem.new('installdirs', 'std/site/home',
                   'std: install under libruby; site: install under site_ruby; home: install under $HOME')\
          {|val, table|
            case val
            when 'std'
              table['rbdir'] = '$librubyver'
              table['sodir'] = '$librubyverarch'
            when 'site'
              table['rbdir'] = '$siterubyver'
              table['sodir'] = '$siterubyverarch'
            when 'home'
              setup_rb_error '$HOME was not set' unless ENV['HOME']
              table['prefix'] = ENV['HOME']
              table['rbdir'] = '$libdir/ruby'
              table['sodir'] = '$libdir/ruby'
            end
          },
      PathItem.new('prefix',  'path', c['prefix'], 'path prefix of target environment'),
      PathItem.new('bindir',  'path', parameterize.call(c['bindir']), 'the directory for commands'),
      PathItem.new('libdir',  'path', parameterize.call(c['libdir']), 'the directory for libraries'),
      PathItem.new('datadir', 'path', parameterize.call(c['datadir']), 'the directory for shared data'),
      PathItem.new('mandir',  'path', parameterize.call(c['mandir']), 'the directory for man pages'),
      PathItem.new('sysconfdir', 'path', parameterize.call(c['sysconfdir']), 'the directory for system configuration files'),
      PathItem.new('localstatedir', 'path', parameterize.call(c['localstatedir']), 'the directory for local state data'),
      PathItem.new('libruby', 'path', libruby, 'the directory for ruby libraries'),
      PathItem.new('librubyver', 'path', librubyver,
                   'the directory for standard ruby libraries'),
      PathItem.new('librubyverarch', 'path', librubyverarch,
                   'the directory for standard ruby extensions'),
      PathItem.new('siteruby', 'path', siteruby,
          'the directory for version-independent aux ruby libraries'),
      PathItem.new('siterubyver', 'path', siterubyver,
                   'the directory for aux ruby libraries'),
      PathItem.new('siterubyverarch', 'path', siterubyverarch,
                   'the directory for aux ruby binaries'),
      PathItem.new('rbdir', 'path', '$siterubyver',
                   'the directory for ruby scripts'),
      PathItem.new('sodir', 'path', '$siterubyverarch',
                   'the directory for ruby extentions'),
      PathItem.new('rubypath', 'path', rubypath,
                   'the path to set to #! line'),
      ProgramItem.new('rubyprog', 'name', rubypath,
                      'the ruby program using for installation'),
      ProgramItem.new('makeprog', 'name', makeprog,
                      'the make program to compile ruby extentions'),
      SelectItem.new('shebang', 'all/ruby/never', 'ruby',
                     'shebang line (#!) editing mode'),
      BoolItem.new('without-ext', 'yes/no', 'no',
                   'does not compile/install ruby extentions')
    ]
  end
  private :standard_entries

  def load_multipackage_entries
    multipackage_entries().each do |ent|
      add ent
    end
  end

  def multipackage_entries
    [
      PackageSelectionItem.new('with', 'name,name...', '', 'ALL',
                               'package names that you want to install'),
      PackageSelectionItem.new('without', 'name,name...', '', 'NONE',
                               'package names that you do not want to install')
    ]
  end
  private :multipackage_entries

  ALIASES = {
    'std-ruby'         => 'librubyver',
    'stdruby'          => 'librubyver',
    'rubylibdir'       => 'librubyver',
    'archdir'          => 'librubyverarch',
    'site-ruby-common' => 'siteruby',     # For backward compatibility
    'site-ruby'        => 'siterubyver',  # For backward compatibility
    'bin-dir'          => 'bindir',
    'bin-dir'          => 'bindir',
    'rb-dir'           => 'rbdir',
    'so-dir'           => 'sodir',
    'data-dir'         => 'datadir',
    'ruby-path'        => 'rubypath',
    'ruby-prog'        => 'rubyprog',
    'ruby'             => 'rubyprog',
    'make-prog'        => 'makeprog',
    'make'             => 'makeprog'
  }

  def fixup
    ALIASES.each do |ali, name|
      @table[ali] = @table[name]
    end
    @items.freeze
    @table.freeze
    @options_re = /\A--(#{@table.keys.join('|')})(?:=(.*))?\z/
  end

  def parse_opt(opt)
    m = @options_re.match(opt) or setup_rb_error "config: unknown option #{opt}"
    m.to_a[1,2]
  end

  def dllext
    @rbconfig['DLEXT']
  end

  def value_config?(name)
    lookup(name).value?
  end

  class Item
    def initialize(name, template, default, desc)
      @name = name.freeze
      @template = template
      @value = default
      @default = default
      @description = desc
    end

    attr_reader :name
    attr_reader :description

    attr_accessor :default
    alias help_default default

    def help_opt
      "--#{@name}=#{@template}"
    end

    def value?
      true
    end

    def value
      @value
    end

    def resolve(table)
      @value.gsub(%r<\$([^/]+)>) { table[$1] }
    end

    def set(val)
      @value = check(val)
    end

    private

    def check(val)
      setup_rb_error "config: --#{name} requires argument" unless val
      val
    end
  end

  class BoolItem < Item
    def config_type
      'bool'
    end

    def help_opt
      "--#{@name}"
    end

    private

    def check(val)
      return 'yes' unless val
      case val
      when /\Ay(es)?\z/i, /\At(rue)?\z/i then 'yes'
      when /\An(o)?\z/i, /\Af(alse)\z/i  then 'no'
      else
        setup_rb_error "config: --#{@name} accepts only yes/no for argument"
      end
    end
  end

  class PathItem < Item
    def config_type
      'path'
    end

    private

    def check(path)
      setup_rb_error "config: --#{@name} requires argument"  unless path
      path[0,1] == '$' ? path : File.expand_path(path)
    end
  end

  class ProgramItem < Item
    def config_type
      'program'
    end
  end

  class SelectItem < Item
    def initialize(name, selection, default, desc)
      super
      @ok = selection.split('/')
    end

    def config_type
      'select'
    end

    private

    def check(val)
      unless @ok.include?(val.strip)
        setup_rb_error "config: use --#{@name}=#{@template} (#{val})"
      end
      val.strip
    end
  end

  class ExecItem < Item
    def initialize(name, selection, desc, &block)
      super name, selection, nil, desc
      @ok = selection.split('/')
      @action = block
    end

    def config_type
      'exec'
    end

    def value?
      false
    end

    def resolve(table)
      setup_rb_error "$#{name()} wrongly used as option value"
    end

    undef set

    def evaluate(val, table)
      v = val.strip.downcase
      unless @ok.include?(v)
        setup_rb_error "invalid option --#{@name}=#{val} (use #{@template})"
      end
      @action.call v, table
    end
  end

  class PackageSelectionItem < Item
    def initialize(name, template, default, help_default, desc)
      super name, template, default, desc
      @help_default = help_default
    end

    attr_reader :help_default

    def config_type
      'package'
    end

    private

    def check(val)
      unless File.dir?("#{PACKAGES_DIRECTORY}/#{val}")
        setup_rb_error "config: no such package: #{val}"
      end
      val
    end
  end

  class MetaConfigEnvironment
    def initialize(config, installer)
      @config = config
      @installer = installer
    end

    def config_names
      @config.names
    end

    def config?(name)
      @config.key?(name)
    end

    def bool_config?(name)
      @config.lookup(name).config_type == 'bool'
    end

    def path_config?(name)
      @config.lookup(name).config_type == 'path'
    end

    def value_config?(name)
      @config.lookup(name).config_type != 'exec'
    end

    def add_config(item)
      @config.add item
    end

    def add_bool_config(name, default, desc)
      @config.add BoolItem.new(name, 'yes/no', default ? 'yes' : 'no', desc)
    end

    def add_path_config(name, default, desc)
      @config.add PathItem.new(name, 'path', default, desc)
    end

    def set_config_default(name, default)
      @config.lookup(name).default = default
    end

    def remove_config(name)
      @config.remove(name)
    end

    # For only multipackage
    def packages
      raise '[setup.rb fatal] multi-package metaconfig API packages() called for single-package; contact application package vendor' unless @installer
      @installer.packages
    end

    # For only multipackage
    def declare_packages(list)
      raise '[setup.rb fatal] multi-package metaconfig API declare_packages() called for single-package; contact application package vendor' unless @installer
      @installer.packages = list
    end
  end

end   # class ConfigTable

