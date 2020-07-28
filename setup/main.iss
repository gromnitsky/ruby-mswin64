;; -*-conf-*-

<%
require 'yaml'
$conf = YAML.load_file(ENV['conf'] || File.join('default.yaml'))
def prefix f; File.join "ruby-#{$conf['ver']}", f; end
ver = $conf["ver"] +'-'+ $conf["release"].to_s
ver_mm = $conf["ver"].split('.')[0..-2].join '.'
ver_mm0 = ver_mm + '.0'
%>

#define AppId "com.github.gromnitsky.ruby-mswin64-<%= ver %>"

[Setup]
AppName=ruby-mswin64
AppVersion=<%= ver %>
AppPublisherURL=https://github.com/gromnitsky/ruby-mswin64
;; windows 7 sp1
MinVersion=6.1.7601
AppId={#AppId}

WizardStyle=classic
WizardResizable=yes
WizardSizePercent=120,120

PrivilegesRequired=lowest
;; installation dir
DefaultDirName={autopf}\ruby-mswin64-<%= ver %>
;; start menu dir
DefaultGroupName=ruby-mswin64 <%= ver %>
DisableProgramGroupPage=yes
LicenseFile=license.txt
Compression=<%= ENV['compression'] || 'lzma2/max' %>
;; Tell Windows Explorer to reload the environment after we modified env vars
ChangesEnvironment=yes
;; put .exe alongside .iss
OutputDir=.

[Types]
Name: "full"; Description: "Everything"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Tasks]
Name: modifypath; Description: &Add ruby.exe, irb.cmd, &&c to PATH.
Name: RUBYOPT; Description: &Enable UTF-8 by default for `Encoding.default_external` via setting RUBYOPT env var to `-Eutf-8` (highly recomended).
Name: SSL_CERT_FILE; Description: &Install the Mozilla CA certificate store. This will NOT interfere with the Windows certificate store. If you uncheck this, expect certificate check errors when opening a TLS connection in Ruby.

[Components]
Name: "program"; Description: "Essentials"; Types: full custom; Flags: fixed
Name: "headers"; Description: "Headers"; Types: full custom
Name: "help"; Description: "API reference, man pages, samples"; Types: full custom

[Files]
Source: "license.txt"; DestDir: "{app}"; Components: program
Source: "<%= prefix('lib/*') %>"; DestDir: "{app}/lib"; Flags: recursesubdirs; Components: program
Source: "<%= ENV['src'] %>/cacert.pem"; DestDir: "{app}\etc"; Components: program; Tasks: SSL_CERT_FILE
Source: "<%= prefix('bin/*') %>"; DestDir: "{app}/bin"; Flags: recursesubdirs; Components: program
Source: "<%= prefix('include/*') %>"; DestDir: "{app}/include"; Flags: recursesubdirs; Components: headers
Source: "<%= prefix('share/*') %>"; DestDir: "{app}/share"; Flags: recursesubdirs; Components: help
Source: "<%= prefix('sample/*') %>"; DestDir: "{app}/sample"; Flags: recursesubdirs; Components: help
Source: "<%= prefix('man/*') %>"; DestDir: "{app}/man"; Flags: recursesubdirs; Components: help
Source: "vc_redist.x64.exe"; DestDir: {app}; Flags: nocompression

[Run]
Filename: {app}\vc_redist.x64.exe; Parameters: "/passive"; \
          StatusMsg: "Installing MS Visual C++ Redistributable..."

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName: "SSL_CERT_FILE"; ValueData: "{app}\etc\cacert.pem"; Flags: uninsdeletevalue; Tasks: SSL_CERT_FILE
Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName: "RUBYOPT"; ValueData: "-Eutf-8"; Tasks: RUBYOPT

[Icons]
Name: "{group}\stdlib"; Filename: "{app}\lib\ruby"
Name: "{group}\samples"; Filename: "{app}\sample"; Components: help
;; each man page is a separate shortcut
<% Dir.glob(File.join ENV['out'], prefix('man/*.html')).each do |f| %>
Name: "{group}\man\<%= File.basename f, '.html' %>"; Filename: "{app}\man\<%= File.basename f %>"; Components: help
<% end %>
Name: "{group}\Interactive Ruby console (irb)"; Filename: "{app}\bin\irb.cmd"; WorkingDir: {%USERPROFILE}
Name: "{group}\API reference console (ri)"; Filename: "{app}\bin\ri.cmd"
Name: "{group}\API reference"; Filename: "{app}\share\rdoc\index.html"
Name: "{group}\web\Bundler"; Filename: https://bundler.io/docs.html
Name: "{group}\web\Changelog"; Filename: https://rubyreferences.github.io/rubychanges/<%= ver_mm %>.html
Name: "{group}\web\Rakefile format"; Filename: https://github.com/ruby/rake/blob/master/doc/rakefile.rdoc
Name: "{group}\web\Reddit"; Filename: https://old.reddit.com/r/ruby/
Name: "{group}\web\Rubyfu"; Filename: https://rubyfu.net/
Name: "{group}\web\The official API documentation"; Filename: https://docs.ruby-lang.org/en/
Name: "{group}\web\minitest"; Filename: http://docs.seattlerb.org/minitest/

[Code]
// pascal! in 2020! *weeps bitterly*

// checks if already installed
function InitializeSetup(): Boolean;
begin
  Result := True;
  if RegKeyExists(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1') then
  begin
    MsgBox('The application has been already installed.', mbCriticalError, MB_OK);
    Result := False;
  end;
end;

// updates PATH env var during (un)install
const
  ModPathName = 'modifypath';
  ModPathType = 'user';

function ModPathDir(): TArrayOfString;
begin
  setArrayLength(Result, 1);
  Result[0] := ExpandConstant('{app}') + '\bin';
end;

#include "modpath.iss"