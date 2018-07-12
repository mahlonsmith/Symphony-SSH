#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'securerandom'
require 'net/ssh'
require 'net/sftp'
require 'inversion'
require 'symphony'
require 'symphony/task'
require 'symphony/tasks/ssh'


### A base class for connecting to a remote host, then uploading and
### executing an Inversion templated script.
###
### This isn't designed to be used directly.  To use this in your
### environment, you'll want to subclass it, add the behaviors
### that make sense for you, then super() back to the parent in the
### #work method.
###
### It expects the payload to contain the following keys:
###
###    host:       (required) The hostname to connect to
###    template:   (required) A path to the Inversion templated script
###    port:       (optional) The port to connect to (defaults to 22)
###    user:       (optional) The user to connect as (defaults to root)
###    key:        (optional) The path to an SSH private key
###    attributes: (optional) Additional data to attach to the template
###    nocleanup:  (optional) Leave the remote script after execution? (default to false)
###    tempdir:    (optional) The destination temp directory.  (defaults to /tmp)
###
###
### Additionally, this class responds to the 'symphony.ssh' configurability
### key.  Currently, you can override the default ssh user and private key.
###
### Textual output of the command is stored in the @output instance variable.
###
###
###    require 'symphony'
###    require 'symphony/tasks/sshscript'
###
###    class YourTask < Symphony::Task::SSHScript
###        timeout 30
###        subscribe_to 'ssh.script.*'
###
###        def work( payload, metadata )
###            status = super
###            puts "Remote script said: %s" % [ @output ]
###            return status.success?
###        end
###    end
###
class Symphony::Task::SSHScript < Symphony::Task

	# Template config
	#
	TEMPLATE_OPTS = {
		ignore_unknown_tags: false,
		on_render_error:     :propagate,
		strip_tag_lines:     true
	}

	# The defaults to use when connecting via SSH
	#
	DEFAULT_SSH_OPTIONS = {
		auth_methods:            [ 'publickey' ],
		compression:             true,
		config:                  false,
		keys_only:               true,
		verify_host_key:         :never,
		global_known_hosts_file: '/dev/null',
		user_known_hosts_file:   '/dev/null'
	}


	### Perform the ssh connection, render the template, send it, and
	### execute it.
	###
	def work( payload, metadata )
		template   = payload[ 'template' ]
		attributes = payload[ 'attributes' ] || {}
		port       = payload[ 'port' ]    || 22
		user       = payload[ 'user' ]    || Symphony::Task::SSH.user
		key        = payload[ 'key'  ]    || Symphony::Task::SSH.key
		nocleanup  = payload[ 'nocleanup' ]
		tempdir    = payload[ 'tempdir' ] || '/tmp'

		raise ArgumentError, "Missing required option 'template'" unless template
		raise ArgumentError, "Missing required option 'host'"     unless payload[ 'host' ]

		remote_filename = self.make_remote_filename( template, tempdir )
		source = self.generate_script( template, attributes )

		ssh_options = DEFAULT_SSH_OPTIONS.merge( port: port, keys: Array(key) )
		ssh_options.merge!(
			logger: Loggability[ Net::SSH ],
			verbose: :debug
		) if payload[ 'debug' ]

		Net::SSH.start( payload['host'], user, ssh_options ) do |conn|
			self.log.debug "Uploading script (%d bytes) to %s:%s." %
				[ source.bytesize, payload['host'], remote_filename ]
			self.upload_script( conn, source, remote_filename )
			self.log.debug "  done with the upload."

			self.run_script( conn, remote_filename, nocleanup )
			self.log.debug "Output was:\n#{@output}"
		end

		return true
	end


	#########
	protected
	#########

	### Generate a unique filename for the script on the remote host,
	### based on +template+ name.
	###
	def make_remote_filename( template, tempdir="/tmp" )
		basename = File.basename( template, File.extname(template) )
		tmpname  = "%s/%s-%s" % [
			tempdir,
			basename,
			SecureRandom.hex( 6 )
		]

		return tmpname
	end


	### Generate a script by loading the script +template+, populating it with
	### +attributes+, and returning the rendered output.
	###
	def generate_script( template, attributes )
		tmpl = Inversion::Template.load( template, TEMPLATE_OPTS )
		tmpl.attributes.merge!( attributes )
		tmpl.task = self

		return tmpl.render
	end


	### Upload the templated +source+ via the ssh +conn+ to an
	### executable file named +remote_filename+.
	###
	def upload_script( conn, source, remote_filename )
		conn.sftp.file.open( remote_filename, "w", 0755 ) do |fh|
			fh.print( source )
		end
	end


	### Run the +remote_filename+ via the ssh +conn+.  The script
	### will be deleted automatically unless +nocleanup+ is true.
	###
	def run_script( conn, remote_filename, nocleanup=false )
		@output = conn.exec!( remote_filename )
		conn.exec!( "rm #{remote_filename}" ) unless nocleanup
	end

end # Symphony::Task::SSHScript

