#!/usr/bin/env ruby
# vim: set nosta noet ts=4 sw=4:

require 'shellwords'
require 'symphony/task' unless defined?( Symphony::Task )


### A base class for connecting to remote hosts, running arbitrary
### commands, and collecting output.
###
### This isn't designed to be used directly.  To use this in your
### environment, you'll want to subclass it, add the behaviors
### that make sense for you, then super() back to the parent in the
### #work method.
###
### It expects the payload to contain the following keys:
###
###    host:    (required) The hostname to connect to
###    command: (required) The command to run on the remote host
###    port:    (optional) The port to connect to (defaults to 22)
###    opts:    (optional) Explicit SSH client options
###    env:     (optional) A hash of environment vars to set for the connection.
###    user:    (optional) The user to connect as (defaults to root)
###    key:     (optional) The path to an SSH private key
###
###
### Additionally, this class responds to the 'symphony.ssh' configurability
### key.  Currently, you can set the 'path' argument, which is the
### full path to the local ssh binary (defaults to '/usr/bin/ssh') and
### override the default ssh user, key, and client opts.
###
### Textual output of the command is stored in the @output instance variable.
###
###
###    require 'symphony'
###    require 'symphony/tasks/ssh'
###
###    class YourTask < Symphony::Task::SSH
###        timeout 5
###        subscribe_to 'ssh.command'
###
###        def work( payload, metadata )
###            status = super
###            puts "Remote host said: %s" % [ @output ]
###            return status.success?
###        end
###    end
###
class Symphony::Task::SSH < Symphony::Task
	extend Configurability

	# The default set of ssh command line flags.
	#
	DEFAULT_SSH_OPTS = %w[
			-e none
			-T
			-x
			-q
			-o CheckHostIP=no
			-o BatchMode=yes
			-o StrictHostKeyChecking=no
	]

	# SSH "informative" stdout output that should be cleaned from the
	# command output.
	SSH_CLEANUP = %r/Warning: no access to tty|Thus no job control in this shell/


	# Configurability API
	#
	configurability( :symphony__ssh ) do

		# The full path to the ssh binary.
		setting :path, default: '/usr/bin/ssh'

		# The default user to use when connecting.
		setting :user, default: 'root'

		# A default Array of ssh client options when connecting
		# to remote hosts.
		setting :opts, default: DEFAULT_SSH_OPTS do |val|
			Array( val )
		end

		# An absolute path to a password-free ssh private key.
		setting :key
	end


	### Perform the ssh connection in 'exec' mode, and retrieve any
	### output from the remote end.
	###
	def work( payload, metadata )
		raise ArgumentError, "Missing required option 'command'" unless payload[ 'command' ]
		raise ArgumentError, "Missing required option 'host'"    unless payload[ 'host' ]

		exitcode = self.open_connection( payload, metadata ) do |reader, writer|
			#self.log.debug "Writing command #{command}..."
			#writer.puts( command )
			self.log.debug "  closing child's writer."
			writer.close
			self.log.debug "  reading from child."
			reader.read
		end

		self.log.debug "SSH exited: %d" % [ exitcode ]
		return exitcode
	end


	#########
	protected
	#########

	### Call ssh and yield the remote IO objects to the caller,
	### cleaning up afterwards.
	###
	def open_connection( payload, metadata=nil )
		raise LocalJumpError, "no block given" unless block_given?
		@output = ''

		port = payload[ 'port' ] || 22
		opts = payload[ 'opts' ] || Symphony::Task::SSH.opts
		user = payload[ 'user' ] || Symphony::Task::SSH.user
		key  = payload[ 'key'  ] || Symphony::Task::SSH.key
		env  = payload[ 'env'  ] || {}

		cmd = []
		cmd << Symphony::Task::SSH.path
		cmd += opts

		cmd << '-p' << port.to_s
		cmd << '-i' << key if key
		cmd << '-l' << user
		cmd << payload[ 'host' ]
		cmd << payload[ 'command' ]
		cmd.flatten!
		self.log.debug "Running SSH command with: %p" % [ Shellwords.shelljoin(cmd) ]

		parent_reader, child_writer = IO.pipe
		child_reader, parent_writer = IO.pipe

		pid = Process.spawn( env, *cmd,
			out:             child_writer,
			in:              child_reader,
			close_others:    true,
			unsetenv_others: true
		)

		child_writer.close
		child_reader.close

		self.log.debug "Yielding back to the run block."
		@output = yield( parent_reader, parent_writer )
		@output = @output.split( /\r?\n/ ).reject{|l| l =~ SSH_CLEANUP }.join
		self.log.debug "  run block done."

	rescue => err
		self.log.error( err.message )
	ensure
		if pid
			active = Process.kill( 0, pid ) rescue false
			Process.kill( :TERM, pid ) if active
			pid, status = Process.waitpid2( pid )
		end
		return status
	end

end # Symphony::Task::SSH

