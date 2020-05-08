require "rbconfig"
require "rdoc/task"

require "bundler/gem_tasks"

desc "Run test"
task :test do
  ruby("run-test.rb")
end

task :default => :test

RDoc::Task.new do |rdoc|
  rdoc.main = "README.md"
  files = [
    "LICENSE.txt",
    "NEWS.md",
    "README.md",
    "lib/**/*.rb",
  ]
  rdoc.rdoc_files.include(*files)
end

benchmark_tasks = []
namespace :benchmark do
  Dir.glob("benchmark/*.yaml") do |yaml|
    name = File.basename(yaml, ".*")
    env = {
      "RUBYLIB" => nil,
      "BUNDLER_ORIG_RUBYLIB" => nil,
    }
    command_line = [
      RbConfig.ruby, "-v", "-S", "benchmark-driver", File.expand_path(yaml),
    ]

    desc "Run #{name} benchmark"
    task name do
      puts("```")
      sh(env, *command_line)
      puts("```")
    end
    benchmark_tasks << "benchmark:#{name}"

    case name
    when /\Aparse/, "shift"
      namespace name do
        desc "Run #{name} benchmark: small"
        task :small do
          puts("```")
          sh(env.merge("N_COLUMNS" => "10"),
             *command_line)
          puts("```")
        end
        benchmark_tasks << "benchmark:#{name}:small"
      end
    end
  end
end

desc "Run all benchmarks"
task :benchmark => benchmark_tasks
