#!/usr/bin/env rake
# vim: set nosta noet ts=4 sw=4:

require 'rake/clean'
require 'pathname'

BASEDIR = Pathname( __FILE__ ).dirname.relative_path_from( Pathname.pwd )
LIBDIR  = BASEDIR + 'lib' + 'symphony'
CLOBBER.include( 'coverage' )

$LOAD_PATH.unshift( LIBDIR.to_s )

if Rake.application.options.trace
    $trace = true
    $stderr.puts '$trace is enabled'
end

task :default => [ :spec, :docs, :package ]


########################################################################
### P A C K A G I N G
########################################################################

require 'rubygems'
require 'rubygems/package_task'
spec = Gem::Specification.new do |s|
	s.email        = 'mahlon@martini.nu'
	s.homepage     = 'http://projects.martini.nu/ruby-modules'
	s.authors      = [ 'Mahlon E. Smith <mahlon@martini.nu>', 'Michael Granger <ged@faeriemud.org>' ]
	s.platform     = Gem::Platform::RUBY
	s.summary      = "Base classes for using Symphony with ssh."
	s.name         = 'symphony-ssh'
	s.version      = '0.1.0'
	s.license      = 'BSD'
	s.has_rdoc     = true
	s.require_path = 'lib'
	s.bindir       = 'bin'
	s.files        = File.read( __FILE__ ).split( /^__END__/, 2 ).last.split
	#s.executables  = %w[]
	s.description  = <<-EOF
	EOF
	s.required_rubygems_version = '>= 2.0.3'
	s.required_ruby_version = '>= 2.0.0'

	s.add_dependency 'symphony', '~> 0.6'
	s.add_dependency 'net-ssh',  '~> 2.9'
	s.add_dependency 'net-sftp', '~> 2.1'

	s.add_development_dependency 'rspec',     '~> 3.0'
	s.add_development_dependency 'simplecov', '~> 0.8'
end

Gem::PackageTask.new( spec ) do |pkg|
	pkg.need_zip = true
	pkg.need_tar = true
end


########################################################################
### D O C U M E N T A T I O N
########################################################################

begin
	require 'rdoc/task'

	desc 'Generate rdoc documentation'
	RDoc::Task.new do |rdoc|
		rdoc.name       = :docs
		rdoc.rdoc_dir   = 'docs'
		rdoc.main       = "README.rdoc"
		rdoc.options    = [ '-f', 'fivefish' ]
		rdoc.rdoc_files = [ 'lib', *FileList['*.rdoc'] ]
	end

	RDoc::Task.new do |rdoc|
		rdoc.name       = :doc_coverage
		rdoc.options    = [ '-C1' ]
	end

rescue LoadError
	$stderr.puts "Omitting 'docs' tasks, rdoc doesn't seem to be installed."
end


########################################################################
### T E S T I N G
########################################################################

begin
	require 'rspec/core/rake_task'
	task :test => :spec

	desc "Run specs"
	RSpec::Core::RakeTask.new do |t|
		t.pattern = "spec/**/*_spec.rb"
	end

	desc "Build a coverage report"
	task :coverage do
		ENV[ 'COVERAGE' ] = "yep"
		Rake::Task[ :spec ].invoke
	end

rescue LoadError
	$stderr.puts "Omitting testing tasks, rspec doesn't seem to be installed."
end


########################################################################
### M A N I F E S T
########################################################################
__END__
lib/symphony/tasks/ssh.rb
lib/symphony/tasks/sshscript.rb
README.rdoc
