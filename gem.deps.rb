# vim: set nosta noet ts=4 sw=4:
source "https://rubygems.org/"

gem 'configurability', '~> 4.0'
gem 'symphony',        '~> 0.13'
gem 'inversion',       '~> 1.3'
gem 'net-ssh',         '~> 6.1'
gem 'net-sftp',        '~> 3.0'

group( :development ) do
	gem 'rake',      '~> 13.0'
	gem 'rspec',     '~> 3.9'
	gem 'simplecov', '~> 0.18'
	gem 'pry',       '~> 0.13'
end

