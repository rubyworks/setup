require 'setup/base'

module Setup

  #
  class Compiler < Base

    #
    def configure
      extdirs.each do |dir|
        Dir.chdir(dir) do
          # unless File.exist?('Makefile') ?
          #load("extconf.rb", true) if File.exist?('extconf.rb')
          ruby("extconf.rb") if File.exist?('extconf.rb')
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
      bash(*[config.makeprog, task].compact)
    end

  end

end

