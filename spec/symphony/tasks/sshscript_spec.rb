
require_relative '../../helpers'
require 'symphony/tasks/sshscript'

context Symphony::Task::SSHScript do

	before( :each ) do
		described_class.configure(
			key:  '/tmp/sekrit.rsa',
			user: 'symphony'
		)
	end

	it_should_behave_like "an object with Configurability"

	describe 'subclassed' do
		let( :instance ) { Class.new(described_class).new('queue') }
		let( :payload ) {
			{ 'template' => 'script', 'host' => 'example.com' }
		}
		let( :opts ) {
			opts = described_class::DEFAULT_SSH_OPTIONS
			opts.merge!(
				:port    => 22,
				:keys    => ['/tmp/sekrit.rsa']
			)
			opts
		}
		let( :template ) { Inversion::Template.new("Hi there, <?attr name?>!") }

		before( :each ) do
			allow( Inversion::Template ).to receive( :load ).and_return( template )
			allow( Dir::Tmpname ).to receive( :make_tmpname ).and_return( "script_temp" )
		end

		it "aborts if there is no template in the payload" do
			expect {
				instance.work( {}, {} )
			}.to raise_exception( ArgumentError, /missing required option 'template'/i )
		end

		it "aborts if there is no host in the payload" do
			expect {
				instance.work({ 'template' => 'boop' }, {} )
			}.to raise_exception( ArgumentError, /missing required option 'host'/i )
		end

		it "adds debugging output if specified in the payload" do
			payload[ 'debug' ] = true

			options = opts.dup
			options.merge!(
				:logger  => Loggability[ Net::SSH ],
				:verbose => :debug
			)

			expect( Net::SSH ).to receive( :start ).with( 'example.com', 'symphony', options )
			instance.work( payload, {} )
		end

		it "attaches attributes to the scripts from the payload" do
			payload[ 'attributes' ] = { :name => 'Handsome' }

			conn = double( :ssh_connection )
			expect( instance ).to receive( :upload_script ).
				with( conn, "Hi there, Handsome!", "/tmp/script_temp" )
			expect( conn ).to receive( :exec! ).with( "/tmp/script_temp" )
			expect( conn ).to receive( :exec! ).with( "rm /tmp/script_temp" )

			expect( Net::SSH ).to receive( :start ).
				with( 'example.com', 'symphony', opts ).and_yield( conn )

			instance.work( payload, {} )
		end

		it "uploads the file and sets it executable" do
			conn = double( :ssh_connection )
			sftp = double( :sftp_connection )
			file = double( :remote_file_obj )
			fh   = double( :remote_filehandle )

			expect( conn ).to receive( :sftp ).and_return( sftp )
			expect( sftp ).to receive( :file ).and_return( file )

			expect( file ).to receive( :open ).
				with( "/tmp/script_temp", "w", 0755 ).and_yield( fh )
			expect( fh ).to receive( :print ).with( "Hi there, !" )

			expect( conn ).to receive( :exec! ).with( "/tmp/script_temp" )
			expect( conn ).to receive( :exec! ).with( "rm /tmp/script_temp" )

			expect( Net::SSH ).to receive( :start ).
				with( 'example.com', 'symphony', opts ).and_yield( conn )

			instance.work( payload, {} )
		end

		it "leaves the remote script in place if asked" do
			payload[ 'nocleanup' ] = true

			conn = double( :ssh_connection )
			expect( instance ).to receive( :upload_script ).
				with( conn, "Hi there, !", "/tmp/script_temp" )
			expect( conn ).to receive( :exec! ).with( "/tmp/script_temp" )
			expect( conn ).to_not receive( :exec! ).with( "rm /tmp/script_temp" )

			expect( Net::SSH ).to receive( :start ).
				with( 'example.com', 'symphony', opts ).and_yield( conn )

			instance.work( payload, {} )
		end

		it "remembers the output of the remote script" do
			conn = double( :ssh_connection )
			expect( instance ).to receive( :upload_script ).
				with( conn, "Hi there, !", "/tmp/script_temp" )
			expect( conn ).to receive( :exec! ).with( "/tmp/script_temp" ).and_return( "Hi there, !" )
			expect( conn ).to receive( :exec! ).with( "rm /tmp/script_temp" )

			expect( Net::SSH ).to receive( :start ).
				with( 'example.com', 'symphony', opts ).and_yield( conn )

			instance.work( payload, {} )
			output = instance.instance_variable_get( :@output )
			expect( output ).to eq( 'Hi there, !' )
		end
	end
end

