# ruby-mswin64

Produce a native Windows build of Ruby using VS2019.

Outputs a portable .zip that requires only [MS Visual C++
Redistributable][] pkg on a target machine or an installer that
integrates the redist pkg, sets the user's path, &c.

**Achtung!** If you need to run Rails, do not use this, use builds
from [RubyInstaller][] project!

[MS Visual C++ Redistributable]: https://aka.ms/vs/16/release/vc_redist.x64.exe
[RubyInstaller]: https://rubyinstaller.org/

The build does **not** use msys2/mingw/cygwin or wsl.

Examples: http://gromnitsky.users.sourceforge.net/ruby/mswin64/

## Reqs

* Win7 sp1 x64 or newer.
* VS 2019 (the 'community' edition will suffice)
* `scoop install git patch`
* Ruby (grab a zip from the link above, unpack it somewhere & add its
  `bin` dir to PATH)
* `scoop install inno-setup` (optional, only if you plan making an
  installer)

## Compilation

1. Clone the repo.
2. Open *x64 Native Tools Command Prompt for VS 2019*.
3. cd to the repo dir & type `rake`.

It'll download vcpkg, build several deps, then download the ruby
tarball & compile it.

To create an installer, type `rake setup`.

The results should be in `_out` dir, e.g.,

* `_out/ruby-2.7.1p83/ruby-2.7.1p83` -- a final portable Ruby
  installation;
* `_out/ruby-2.7.1p83/ruby-2.7.1p83-1.zip` -- the same but as an
  archive.
* `_out/ruby-2.7.1p83/ruby-2.7.1p83-1.exe` -- w00t

## Caveats

* The included openssl doesn't use the windows certificate store,
  hence, we ship [The Mozilla CA certificate store in PEM format][] as
  $install_prefix/cert.pem.

  To override this, set `SSL_CERT_FILE` env var with a full path to a
  new .pem file or, alternatively, use a technique described in
  [net_http_ssl_fix][] gem on a per-project basis.

* File ops throw on exceeding the [MAX_PATH][] limit.

* dbm & gdbm extensions are absent.

* At the time of writing, nokogiri gem, unfortunately, does not
  compile.

* This is an experiment.

[The Mozilla CA certificate store in PEM format]: https://curl.haxx.se/ca/cacert.pem
[net_http_ssl_fix]: https://github.com/liveeditor/net_http_ssl_fix
[MAX_PATH]: https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file

## Hints

* If you plan to distribute it as a part of your app, you may safely
  leave only `bin` & `dir` dirs to greatly save space.

* Run `gem env` to see where your gems are installed. By default they
  are downloaded to `$installation/lib/ruby/gems/2.7.0/`, thus run
  `gem install ... --user-install` to put them into your home dir.

## License

MIT
