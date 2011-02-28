$LOAD_PATH.unshift 'lib'
require "ruby-xen/VERSION"

Gem::Specification.new do |s|
s.name = "ruby-xen"
s.version = Ruby-xen::VERSION
s.date = Time.now.strftime('%Y-%m-%d')
s.homepage = "http://github.com/foexle/ruby-xen"
s.email = "info@honeybutcher.de"
s.authors = [ "Clemens Kofler", "Heiko Krämer" ]
s.has_rdoc = false

s.files = %w( README.md Rakefile LICENSE )
s.files += Dir.glob("lib/**/*")
s.files += Dir.glob("man/**/*")
s.files += Dir.glob("test/**/*")

# s.executables = %w( ruby-xen )
s.description = <<desc
A simple ruby module to admin xen instances
desc
end
