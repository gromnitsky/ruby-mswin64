# ruby-mswin64

Produce a native Windows build of Ruby using VS2019.

Outputs a portable .zip that requires only small [MS Visual C++
Redistributable][] pkg on a target machine.

[MS Visual C++ Redistributable]: https://aka.ms/vs/16/release/vc_redist.x64.exe

The build does **not** use msys2/mingw/cygwin or wsl.

Examples: http://gromnitsky.users.sourceforge.net/ruby/mswin64/

## Reqs

* Win7 x64
* VS2019
* Ruby (testes w/ 2.7.1, grab a zip from the link above, unpack it
  somewhere & add its `bin` dir to PATH)

## Compilation

1. Clone the repo.
2. Open *x64 Native Tools Command Prompt for VS 2019*.
3. cd to the repo dir & type `rake`.

It'll download vcpkg, build several deps, then download the ruby
tarball & compile it.

The results should be in `_out` dir, e.g.,

* `_out/ruby-2.7.1p83/ruby-2.7.1p83` -- a final portable Ruby
  installation;
* `_out/ruby-2.7.1p83/ruby-2.7.1p83-1.zip` -- the same but as an
  archive.

## Caveats

* The included openssl doesn't use the windows certificate
  store. Therefore to be able to make TLS requests, fetch [The Mozilla
  CA certificate store in PEM format][] and set `SSL_CERT_FILE` env
  var with a full path to the file.

  Alternatively, use a technique described in [net_http_ssl_fix][] gem
  on a per-project basis.

* dbm & gdbm extensions are absent.

* At the time of writing, nokogiri gem, unfortunately, does not
  compile.

* This is an experiment.

[The Mozilla CA certificate store in PEM format]: https://curl.haxx.se/ca/cacert.pem
[net_http_ssl_fix]: https://github.com/liveeditor/net_http_ssl_fix

## Hints

* If you plan to distribute it as a part of your app, you may safely
  remove `include` & `share` dirs to greatly save space.

* Run `gem env` to see where your gems are installed. By default they
  are downloaded to `$installation/lib/ruby/gems/2.7.0/`, thus run
  `gem install ... --user-install` to put them into your home dir.

## License

MIT
