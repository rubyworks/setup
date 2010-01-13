require 'setup/installer'

Test Setup::Installer do

  Unit :files => "finds all files to be installed" do
    prefix = File.join(Dir.tmpdir, 'setup', 'fauxroot')
    installer = Setup::Installer.new(nil, nil, :install_prefix=>prefix)
    Setup::TYPES.each do |type|
      installer.pry.files(type).each do |f|
        pending
      end
    end
  end

  Unit :destination => "applies install_prefix" do
    prefix = File.join(Dir.tmpdir, 'setup', 'fauxroot')
    installer = Setup::Installer.new(nil, nil, :install_prefix=>prefix)
    Setup::TYPES.each do |type|
      installer.pry.files(type).each do |file|
        dest = File.join(Dir.tmpdir, 'setup', 'faux', type)
        dir  = installer.pry.destination(dest, file)
        dir.assert.start_with?(prefix)
      end
    end
  end

end

