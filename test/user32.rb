require 'fiddle'
require 'fiddle/import'

module User32
  extend Fiddle::Importer
  dlload 'user32'
  extern 'int MessageBoxA(int, char*, char*, int)'
end

User32::MessageBoxA 0, RUBY_DESCRIPTION, "", 0
