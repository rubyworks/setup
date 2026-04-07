Gem::Specification.new do |s|
  s.name        = 'setup'
  s.version     = '5.2.0'
  s.summary     = 'Ruby Classic Installer'
  s.description = 'Setup.rb is the classic install.rb-style installer for ' \
                  'Ruby projects, originally created by Minero Aoki. This is ' \
                  'a stand-alone packaging of setup.rb so users no longer need ' \
                  'to bundle the script with each project.'
  s.authors     = ['Trans', 'Minero Aoki']
  s.email       = ['transfire@gmail.com']
  s.homepage    = 'https://github.com/rubyworks/setup'
  s.licenses    = ['BSD-2-Clause', 'LGPL-2.1']

  s.files       = Dir['lib/**/*', 'bin/*', 'setup.rb',
                      'LICENSE.txt', 'NOTICE.txt', 'README.rdoc', 'HISTORY.rdoc']
  s.executables = ['setup.rb']
  s.require_paths = ['lib']
end
