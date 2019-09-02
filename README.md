
symphony-ssh
############

Description
------------

This is a small collection of base classes used for interacting with
remote machines over ssh.  With them, you can use AMQP (via Symphony) to
run batch commands, execute templates as scripts, and perform any
batch/remoting stuff you can think of without the need of a separate
client agent.

These classes assume you have a user that can connect and login to
remote machines using a password-less ssh keypair.  They are not meant
to be used directly.  Subclass them!

See the rdoc for additional information and examples.


Options
-------

Symphony-ssh uses
Configurability[https://rubygems.org/gems/configurability] to determine
behavior.  The configuration is a YAML[http://www.yaml.org/] file. 

    symphony:
        ssh:
            path: /usr/bin/ssh
            user: root
            key: /path/to/a/private_key.rsa
            opts:
              - -e
              - none
              - -T
              - -x
              - -o
              - CheckHostIP=no'
              - -o
              - BatchMode=yes'
              - -o
              - StrictHostKeyChecking=no

**NOTE**: If you've upgrade from a version pre 0.2.0, the
Configurability path has changed from `symphony_ssh`, to an `ssh` key
under the `symphony` top level.


### path

The absolute path to the ssh binary.

### user

The default user to connect to remote hosts with.  This can be
changed per connection in the AMQP payload.

### key

An absolute path to a password-less ssh private key.

### opts

SSH client options, passed to the ssh binary on the command line.  Note
that the defaults have been tested fairly extensively, these are just
exposed if you have very specific needs and you know what you're doing.


Installation
-------------

    gem install symphony-ssh


Contributing
------------

You can check out the current development source with Mercurial
[here](http://code.martini.nu/symphony-ssh), or via a mirror:

 * github: https://github.com/mahlonsmith/Symphony-SSH
 * SourceHut: https://hg.sr.ht/~mahlon/Symphony-SSH

After checking out the source, run:

    $ rake

This task will run the tests/specs and generate the API documentation.

If you use {rvm}[http://rvm.io/], entering the project directory will
install any required development dependencies.


License
-------

Copyright (c) 2014-2018, Mahlon E. Smith and Michael Granger
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

* Neither the name of the author/s, nor the names of the project's
  contributors may be used to endorse or promote products derived from this
  software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


