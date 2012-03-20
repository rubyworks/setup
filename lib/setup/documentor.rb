require 'setup/base'

module Setup

  # As of v0.5.1 Setup.rb no longer support the document phase at all. The
  # document phase would generate *ri* documentation for a project, adding in
  # with the rest of ri documentation. After careful consideration, it has
  # become clear that it is better for documentation to be left up to dedicated
  # tools. For example, you could easily document your Ruby install site
  # location yourself with
  #
  #   $ rdoc --ri-site /usr/local/lib/site_ruby
  #
  # Using of course, whichever path is appropriate to your system.
  #
  # This descision also allows setup.rb to be less Ruby-specific, and useful
  # as a more general install tool.
  #
  # @deprecated Setup.rb no longer generate ri documentation, ever.
  #
  class Documentor < Base

    #
    def document
      return if config.no_doc

      exec_ri
      exec_yri
    end

    # Generate ri documentation.
    #
    # @todo Should we run rdoc programmatically instead of shelling out?
    #
    def exec_ri
      case config.type #installdirs
      when 'home'
        output = "--ri"
      when 'site'
        output = "--ri-site"
      when 'std', 'ruby'
        output  = "--ri-site"
      else
        abort "bad config: should not be possible -- type=#{config.type}"
      end

      opt = []
      opt << "-U"
      opt << "-q" #if quiet?
      #opt << "-D" #if $DEBUG
      opt << output

      unless project.document
        files = []
        files << 'lib' if project.find('lib')
        files << 'ext' if project.find('ext')
      else
        files = []
        #files = File.read('.document').split("\n")
        #files.reject!{ |l| l =~ /^\s*[#]/ || l !~ /\S/ }
        #files.collect!{ |f| f.strip }
      end

      opt.concat(files)

      opt.flatten!

      cmd = "rdoc " + opt.join(' ')

      if trial?
        puts cmd
      else
        begin
          success = system(cmd)
          raise unless success
          #require 'rdoc/rdoc'
          #::RDoc::RDoc.new.document(opt)
          io.puts "Ok ri." #unless quiet?
        rescue Exception
          $stderr.puts "ri generation failed"
          $stderr.puts "command was: '#{cmd}'"
          #$stderr.puts "proceeding with install..."
        end
      end
    end

    #
    # Generate YARD Ruby Index documention.
    #
    def exec_yri

    end

    # Generate rdocs. Needs project <tt>name</tt>.
    #
    # @deprecated This is not being used. It's here in case we decide
    #   to add the feature back in the future.
    #
    def exec_rdoc
      main = Dir.glob("README{,.*}", File::FNM_CASEFOLD).first

      if File.exist?('.document')
        files = File.read('.document').split("\n")
        files.reject!{ |l| l =~ /^\s*[#]/ || l !~ /\S/ }
        files.collect!{ |f| f.strip }
      else
        files = []
        files << main  if main
        files << 'lib' if File.directory?('lib')
        files << 'ext' if File.directory?('ext')
      end

      checkfiles = (files + files.map{ |f| Dir[File.join(f,'*','**')] }).flatten.uniq
      if FileUtils.uptodate?('doc/rdoc', checkfiles)
        puts "RDocs look current."
        return
      end

      output    = 'doc/rdoc'
      title     = (PACKAGE.capitalize + " API").strip if PACKAGE
      template  = config.doctemplate || 'html'

      opt = []
      opt << "-U"
      opt << "-q" #if quiet?
      opt << "--op=#{output}"
      #opt << "--template=#{template}"
      opt << "--title=#{title}"
      opt << "--main=#{main}"     if main
      #opt << "--debug"
      opt << files

      opt = opt.flatten

      cmd = "rdoc " + opt.join(' ')

      if trial?
        puts cmd 
      else
        begin
          system(cmd)
          #require 'rdoc/rdoc'
          #::RDoc::RDoc.new.document(opt)
          puts "Ok rdoc." unless quiet?
        rescue Exception
          puts "Fail rdoc."
          puts "Command was: '#{cmd}'"
          puts "Proceeding with install anyway."
        end
      end
    end

  end

end
