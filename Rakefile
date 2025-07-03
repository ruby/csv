require "rbconfig"
require "rdoc/task"
require "yaml"

require "bundler/gem_tasks"

spec = Bundler::GemHelper.gemspec

desc "Run test"
task :test do
  ruby("run-test.rb")
end

task :default => :test

namespace :warning do
  desc "Treat warning as error"
  task :error do
    def Warning.warn(*message)
      super
      raise "Treat warning as error:\n" + message.join("\n")
    end
  end
end

RDoc::Task.new do |rdoc|
  rdoc.options = spec.rdoc_options
  rdoc.rdoc_files.include(*spec.source_paths)
  rdoc.rdoc_files.include(*spec.extra_rdoc_files)
end

benchmark_tasks = []
namespace :benchmark do
  Dir.glob("benchmark/*.yaml").sort.each do |yaml|
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

  namespace :old_versions do
    desc "Install used old versions"
    task :install do
      old_versions = []
      Dir.glob("benchmark/*.yaml") do |yaml|
        YAML.load_file(yaml)["contexts"].each do |context|
          old_version = (context["gems"] || {})["csv"]
          old_versions << old_version if old_version
        end
      end
      old_versions.uniq.sort.each do |old_version|
        ruby("-S", "gem", "install", "csv", "-v", old_version)
      end
    end
  end
end

desc "Run all benchmarks"
task :benchmark => benchmark_tasks

release_task = Rake.application["release"]
# We use Trusted Publishing.
release_task.prerequisites.delete("build")
release_task.prerequisites.delete("release:rubygem_push")
release_task_comment = release_task.comment
if release_task_comment
  release_task.clear_comments
  release_task.comment = release_task_comment.gsub(/ and build.*$/, "")
end
