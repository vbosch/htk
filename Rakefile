
begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name     'htk'
  authors  'Vicente Bosch'
  email  'vbosch@gmail.com'
  url  'http://github.com/vbosch/htk'
  ignore_file  '.gitignore'
}

