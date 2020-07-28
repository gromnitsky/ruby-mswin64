require 'yaml'

$conf = YAML.load_file(ENV['conf'] || File.join(__dir__, 'default.yaml'))
def out f=''; File.join (ENV['out'] || "_out/ruby-#{$conf["ver"]}"), f; end
install_prefix = out "ruby-#{$conf["ver"]}"

rule '.tar.gz' do |t|
  fetch $conf["tarballs"][File.basename t.name]["url"], t.name
end

rule '.zip' do |t|
  fetch $conf["tarballs"][File.basename t.name]["url"], t.name
end

rule '.unpack' => '.tar.gz' do |t|
  tar_xfz t.prerequisites.first, 1, t.prerequisites.first.sub(/.tar.gz$/, '')
  touch t.name
end

rule '.unzip' => '.zip' do |t|
  sh 'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
     '-Command', 'Expand-Archive', '-Path', t.prerequisites.first,
     '-DestinationPath', out()
  touch t.name
end

file out('vc_redist.x64.exe') do |t|
  fetch $conf["tarballs"][File.basename t.name]["url"], t.name
end

# compile vcpkg.exe
task "vcpkg-configure" => out('vcpkg.configure')
file out('vcpkg.configure') => out('vcpkg.unpack') do |t|
  cd out('vcpkg') do
    sh 'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
       File.join('scripts', 'bootstrap.ps1'), '-disableMetrics'
  end
  touch t.name
end

# compile all the deps
file out('vcpkg.deps') => out('vcpkg.configure') do |t|
  cd out('vcpkg') do
    sh './vcpkg', '--triplet', 'x64-windows', 'install',
       'openssl', 'readline', 'zlib'
  end
  touch t.name
end

# compile ruby
file out('ruby.build') => [out('vcpkg.deps'), out('ruby.unpack')] do |t|
  ENV['INCLUDE'] += ";"+wj(out 'vcpkg/installed/x64-windows/include')
  ENV['LIB'] += ";"+wj(out 'vcpkg/installed/x64-windows/lib')
  ENV['PATH'] += ";"+wj(out 'vcpkg/installed/x64-windows/bin')
  prefix = wj install_prefix

  cd out('ruby') do
    sh 'win32/configure.bat',
       '--prefix='+prefix
    sh "nmake"
    sh "nmake install"
  end
  cp_r Dir.glob(File.join out('vcpkg/installed/x64-windows/bin'), '*.dll'),
       File.join(prefix, 'bin/')
  touch t.name
end

file out('rdoc.darkfish') => out('ruby.build') do |t|
  to = wj install_prefix, 'rdoc'
  cd out('ruby') do
    # rdoc `--root` option doesn't work since (at least) 2015
    sh 'rdoc', '-o', to,  '-m', 'README.md'
  end
  touch t.name
end

# copy samples; convert man pages to html
file out('ruby.build.post') => [out('rdoc.darkfish'), out('mdocml.unzip')] do |t|
  rm_rf File.join install_prefix, 'share/man'
  rm_rf File.join install_prefix, 'share/doc'
  cp_r out('ruby/sample'), install_prefix

  # the reason this is not a rule-based, but a stupid loop, is that
  # after first run, the ruby src is not downloaded yet, hence rake
  # won't find any .1 files
  to = File.join(install_prefix, 'man')
  mkdir_p to
  ENV['PATH'] += ';'+out('mdocml-1.13.1-win32-embedeo-02/bin')
  Dir.glob(out('ruby/man/*.[1-9]')).each do |f|
    next if f =~ /goruby/
    sh "mandoc -Thtml -Ostyle=man.css #{f} > #{File.join to, File.basename(f)+'.html' }"
  end
  cp 'man.css', to
  touch t.name
end

zip = install_prefix + "-#{$conf["release"]}.zip"
file zip => out('ruby.build.post') do |t|
  rm_f t.name
  sh 'powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
     '-Command', 'Compress-Archive', '-Path', install_prefix,
     '-DestinationPath', t.name
end
task :default => zip

file out('license.txt') => ['setup/license_prefix.txt', out('ruby.unpack')] do |t|
  ENV['out'] = out()
  sh "erb -T- #{t.prerequisites.first} > #{t.name}"
end

# transform inno setup files
#
# and people say Make has a cryptic syntax
rule(/#{out()}.+\.iss$/ => [
       proc {|dest| 'setup/' + File.basename(dest) }, out('ruby.build.post')
]) do |t|
  mkdir_p File.dirname t.name
  ENV['src'] = __dir__
  ENV['out'] = out()
  sh "erb #{t.source} > #{t.name}"
end

setup = install_prefix + "-#{$conf["release"]}.exe"
file setup => [out('main.iss'), out('modpath.iss'), out('vc_redist.x64.exe'),
               out('ruby.build.post'), out('license.txt')] do |t|
  sh "iscc", "/DCOMPRESSION=#{ENV['compression'] || 'lzma2/max'}", '/Q',
     '/F'+File.basename(t.name, '.exe'), t.prerequisites.first
end
task :setup => setup

task :upload => [zip, setup] do |t|
  sh 'scp', t.prerequisites.join(' '), 'gromnitsky@web.sourceforge.net:/home/user-web/gromnitsky/htdocs/ruby/mswin64/'
end



require 'open-uri'
require 'rubygems/package'
require 'digest/sha1'

# openssl for windows doesn't use the windows certificate store!
#
# wget https://curl.haxx.se/ca/cacert.pem
ENV['SSL_CERT_FILE'] = File.join __dir__, 'cacert.pem'

def fetch from, to
  puts "fetch #{from} to `#{to}`" if verbose
  URI.open(from) do |io|
    mkdir_p File.dirname to
    File.open(to, 'wb') { |f| f.write io.read }
  end
  if Digest::SHA1.hexdigest(File.binread to) != $conf["tarballs"][File.basename to]["sha1"]
    fail "sha1 doesn't match"
  end
end

def tar_xfz archive, strip_componenets, to
  puts "unpack #{archive} to `#{to}`" if verbose
  File.open(archive, 'rb') do |file|
    Zlib::GzipReader.wrap(file) do |gz|
      Gem::Package::TarReader.new(gz) do |tar|
        tar.each do |entry|
          next if entry.directory?

          path = entry.full_name.split(File::SEPARATOR)[strip_componenets..-1]
          if path.size > 0
            path = File.join to, path
            FileUtils.mkdir_p File.dirname path
            File.open(path, 'wb') { |f| f.write entry.read }
            File.utime entry.header.mtime, entry.header.mtime, path
          end
        end
      end
    end
  end
end


def wj *rest; File.absolute_path(File.join(*rest)).split('/').join '\\'; end
