require 'setup/base'

module Setup

  #
  class Compiler < Base

    #
    def compiles?
      !extdirs.empty?
      #extdirs.any?{ |dir| File.exist?(File.join(dir, 'extconf.rb')) }
    end

    #
    def configure
      extdirs.each do |dir|
        Dir.chdir(dir) do
          if File.exist?('extconf.rb') && !FileUtils.uptodate?('Makefile', ['extconf.rb'])
            #load("extconf.rb", true)
            ruby("extconf.rb")
          end
        end
      end
    end

    #
    def compile
      extdirs.each do |dir|
        Dir.chdir(dir) do
          make
        end
      end
    end

    #
    def clean
      extdirs.each do |dir|
        Dir.chdir(dir) do
          make('clean')
        end
      end
    end

    #
    def distclean
      extdirs.each do |dir|
        Dir.chdir(dir) do
          make('distclean')
        end
      end
    end

    # TODO: get from project
    def extdirs
      Dir['ext/**/*/{MANIFEST,extconf.rb}'].map do |f|
        File.dirname(f)
      end.uniq
    end

    #
    def make(task=nil)
      return unless File.exist?('Makefile')
      bash(*[config.makeprog, task].compact)
    end

  end

end

