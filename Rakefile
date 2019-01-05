require "bundler/gem_tasks"
require "open3"

desc "Run test"
task :test do
  ruby("run-test.rb")
end

task :default => :test

benchmark_tasks = []
namespace :benchmark do
  Dir.glob("benchmark/*.yaml") do |yaml|
    name = File.basename(yaml, ".*")
    desc "Run #{name} benchmark"
    task name do
      puts("```")
      ruby("-v", "-S", "benchmark-driver", File.expand_path(yaml))
      puts("```")
    end
    benchmark_tasks << "benchmark:#{name}"
  end
end

desc "Run all benchmarks"
task :benchmark => benchmark_tasks
