require 'rake/testtask'

#desc 'Default: run specs.'
task :default => :tests
 
#desc "Run specs"
Rake::TestTask.new(:tests) do |t|
	t.test_files = FileList["./test/*Test.rb"]
end