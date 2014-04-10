PROJECT_NAME = "AFSpecWorking"
SPECS_TARGET_NAME = "Specs"
PROJECT_ROOT = File.dirname(__FILE__)
BUILD_DIR = File.join(PROJECT_ROOT, "build")

def configuration_build_dir
  File.join(BUILD_DIR, build_configuration)
end

def system_or_exit(cmd, stdout = nil)
  puts "Executing #{cmd}"
  cmd += " >#{stdout}" if stdout
  system(cmd) or raise "******** Build failed ********"
end

def output_file(target)
  output_dir = if ENV['IS_CI_BOX']
    ENV['CC_BUILD_ARTIFACTS']
  else
    Dir.mkdir(BUILD_DIR) unless File.exists?(BUILD_DIR)
    BUILD_DIR
  end

  output_file = File.join(output_dir, "#{target}.output")
  puts "Output: #{output_file}"
  output_file
end

def build_configuration
  production_build? ? "ProductionRelease" : "Release"
end

def production_build?
  ENV["PRODUCTION"]
end

task default: [:trim_whitespace, :specs]
task :cruise do
  Rake::Task[:clean].invoke
  Rake::Task[:specs].invoke
end
task all: :cruise

task :trim_whitespace do
  system_or_exit(%Q[git status --short | awk '{if ($1 != "D" && $1 != "R") print $2}' | grep -e '.*\.[mh]$' | xargs sed -i '' -e 's/	/    /g;s/ *$//g;'])
end

task :clean do
  system_or_exit(%Q[xcodebuild -project #{PROJECT_NAME}.xcodeproj -alltargets -configuration #{build_configuration} clean SYMROOT=#{BUILD_DIR}], output_file("clean"))
end

task :build_specs do
  system_or_exit(%Q[xcodebuild -workspace #{PROJECT_NAME}.xcworkspace -scheme #{SPECS_TARGET_NAME} -configuration #{build_configuration} build CONFIGURATION_BUILD_DIR=#{configuration_build_dir} SYMROOT=#{BUILD_DIR}], output_file("specs"))
end

task :build_all do
  system_or_exit(%Q[xcodebuild -project #{PROJECT_NAME}.xcodeproj -alltargets -configuration #{build_configuration} build CONFIGURATION_BUILD_DIR=#{configuration_build_dir} SYMROOT=#{BUILD_DIR}], output_file("build_all"))
end

task specs: :build_specs do
  build_dir = configuration_build_dir
  ENV["DYLD_FRAMEWORK_PATH"] = build_dir
  ENV["CEDAR_REPORTER_CLASS"] = "CDRColorizedReporter"
  system_or_exit(File.join(build_dir, SPECS_TARGET_NAME))
end

