
require_relative '../../helpers'
require 'symphony/tasks/ssh'

context Symphony::Task::SSH do
	let( :ssh ) { (Pathname( __FILE__ ).dirname.parent.parent + 'fake_ssh').realpath }

	before( :each ) do
		described_class.configure(
			path: ssh.to_s,
			key:  '/tmp/sekrit.rsa',
			user: 'symphony'
		)
	end

	it_should_behave_like "an object with Configurability"

	describe 'subclassed' do
		let( :instance ) { Class.new(described_class).new('queue') }
		let( :payload ) {
			{ 'command' => 'woohoo', 'host' => 'example.com' }
		}

		it "aborts if there is no command in the payload" do
			expect {
				instance.work( {}, {} )
			}.to raise_exception( ArgumentError, /missing required option 'command'/i )
		end

		it "aborts if there is no host in the payload" do
			expect {
				instance.work({ 'command' => 'boop' }, {} )
			}.to raise_exception( ArgumentError, /missing required option 'host'/i )
		end

		it "builds the proper command line" do
			pipe = double( :fake_pipes ).as_null_object
			allow( IO ).to receive( :pipe ).and_return([ pipe, pipe ])

			args = [
				'-p', '22', '-i', '/tmp/sekrit.rsa', '-l', 'symphony', 'example.com'
			]

			expect( Process ).to receive( :spawn ).with(
				*[ ssh.to_s, described_class.opts, args ].flatten,
				:out => pipe, :in => pipe, :close_others => true
			).and_return( 12 )

			expect( Process ).to receive( :waitpid2 ).with( 12 ).and_return([ 12, 1 ])

			code = instance.work( payload, {} )
			expect( code ).to eq( 1 )
		end

		it "execs and captures output" do
			code = instance.work( payload, {} )
			expect( code ).to eq( 0 )

			output = instance.instance_variable_get( :@output )
			expect( output ).to eq( 'Hi there!' )
		end
	end
end

