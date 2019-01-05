require "bundler/gem_tasks"

desc "Run test"
task :test do
  ruby("run-test.rb")
end

task :default => :test

benchmark_tasks = []
namespace :benchmark do
  Dir.glob("benchmark/*.yaml") do |yaml|
    name = File.basename(yaml, ".*")
    env = {
      "RUBYLIB" => nil,
      "BUNDLER_ORIG_RUBYLIB" => nil,
    }
    command_line = [
      FileUtils::RUBY, "-v", "-S", "benchmark-driver", File.expand_path(yaml),
    ]

    desc "Run #{name} benchmark"
    task name do
      puts("```")
      sh(env, *command_line)
      puts("```")
    end
    benchmark_tasks << "benchmark:#{name}"

    case name
    when "parse"
      namespace :parse do
        desc "Run #{name} benchmark: small"
        task :small do
          puts("```")
          sh(env.merge("N_COLUMNS" => "10"),
             *command_line)
          puts("```")
        end
        benchmark_tasks << "benchmark:parse:small"
      end
    end
  end
end

desc "Run all benchmarks"
task :benchmark => benchmark_tasks
