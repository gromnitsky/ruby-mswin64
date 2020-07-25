;; -*-conf-*-

<%
require 'yaml'
$conf = YAML.load_file(ENV['conf'] || File.join('default.yaml'))
def prefix f; File.join "ruby-#{$conf['ver']}", f; end
ver_mm = $conf["ver"].split('.')[0..-2].join '.'
ver_mm0 = ver_mm + '.0'
%>

#define AppId "com.github.gromnitsky.ruby-mswin64"

[Setup]
AppName=ruby-mswin64
AppVersion=<%= $conf["ver"] +'-'+ $conf["release"].to_s %>
AppPublisherURL=https://github.com/gromnitsky/ruby-mswin64
;; windows 7 sp1
MinVersion=6.1.7601
AppId={#AppId}

WizardStyle=classic
WizardResizable=yes
WizardSizePercent=120,120

PrivilegesRequired=lowest
;; installation dir
DefaultDirName={autopf}\ruby-mswin64
;; start menu dir
DefaultGroupName=ruby-mswin64
LicenseFile=license.txt
;Compression=none
;; Tell Windows Explorer to reload the environment after we modified env vars
ChangesEnvironment=yes
;; put .exe alongside .iss
OutputDir=.

[Types]
Name: "full"; Description: "Everything"
Name: "custom"; Description: "Custom installation"; Flags: iscustom

[Tasks]
Name: modifypath; Description: &Add ruby.exe, irb.cmd, &&c to PATH.
Name: SSL_CERT_FILE; Description: &Install the Mozilla CA certificate store. This will NOT interfere with the Windows certificate store. If you uncheck this, expect certificate check errors when opening a TLS connection in Ruby.

[Components]
Name: "program"; Description: "Essentials"; Types: full custom; Flags: fixed
Name: "headers"; Description: "Headers"; Types: full custom
Name: "help"; Description: "API reference & samples"; Types: full custom

[Files]
Source: "<%= prefix('lib/*') %>"; DestDir: "{app}/lib"; Flags: recursesubdirs; Components: program
Source: "<%= ENV['src'] %>/cacert.pem"; DestDir: "{app}\etc"; Components: program; Tasks: SSL_CERT_FILE
Source: "<%= prefix('bin/*') %>"; DestDir: "{app}/bin"; Flags: recursesubdirs; Components: program
Source: "<%= prefix('include/*') %>"; DestDir: "{app}/include"; Flags: recursesubdirs; Components: headers
Source: "<%= prefix('share/*') %>"; DestDir: "{app}/share"; Flags: recursesubdirs; Components: help
Source: "<%= prefix('sample/*') %>"; DestDir: "{app}/sample"; Flags: recursesubdirs; Components: help

[Registry]
Root: HKCU; Subkey: "Environment"; ValueType:string; ValueName: "SSL_CERT_FILE"; ValueData: "{app}\etc\cacert.pem"; Flags: uninsdeletevalue; Tasks: SSL_CERT_FILE

[Icons]
Name: "{group}\stdlib"; Filename: "{app}\lib\ruby"
Name: "{group}\samples"; Filename: "{app}\sample"; Components: help
Name: "{group}\Interactive Ruby console (irb)"; Filename: "{app}\bin\irb.cmd"; WorkingDir: {%USERPROFILE}
Name: "{group}\API reference console (ri)"; Filename: "{app}\bin\ri.cmd"
Name: "{group}\Reddit"; Filename: https://old.reddit.com/r/ruby/
Name: "{group}\doc\Official API Documentation"; Filename: https://docs.ruby-lang.org/en/<%= ver_mm0 %>/
Name: "{group}\doc\Bundler"; Filename: https://bundler.io/docs.html
Name: "{group}\doc\Rakefile format"; Filename: https://github.com/ruby/rake/blob/master/doc/rakefile.rdoc
Name: "{group}\doc\minitest"; Filename: http://docs.seattlerb.org/minitest/
Name: "{group}\doc\Changelog"; Filename: https://rubyreferences.github.io/rubychanges/<%= ver_mm %>.html
Name: "{group}\doc\man ruby"; Filename: https://manpages.debian.org/unstable/ruby/ruby.1.en.html
Name: "{group}\doc\man irb"; Filename: https://manpages.debian.org/unstable/ruby/irb.1.en.html
Name: "{group}\doc\man erb"; Filename: https://manpages.debian.org/unstable/ruby/erb.1.en.html

[Code]
// pascal! in 2020! *weeps bitterly*

// checks if already installed
function InitializeSetup(): Boolean;
begin
  Result := True;
  if RegKeyExists(HKEY_CURRENT_USER, 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{#AppId}_is1') then
  begin
    MsgBox('The application has been already installed.' + #13#10 + 'If you are upgrading, remove the old version first.', mbCriticalError, MB_OK);
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