require "bundler/gem_tasks"
require "open3"

desc "Run test"
task :test do
  ruby("run-test.rb")
end

task :default => :test

desc "Run benchmark scripts"
task :benchmark do
  Dir.glob(File.expand_path('./benchmark/*.yml', __dir__)).each do |yaml|
    stdout, stderr, status = Open3.capture3("benchmark-driver", yaml)
    yaml.gsub!(Dir.pwd, '.')
    puts "\n```\n$ benchmark-driver #{yaml}\n#{stdout}```\n\n"
    unless stderr.empty?
      $stderr.puts "stderr:\n```\n#{stderr}```"
    end
  end
end
