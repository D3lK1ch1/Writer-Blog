require 'rake/clean'
require 'pathname'

CLEAN.include('_site/', '.jekyll-cache/')

desc "Build the Jekyll site"
task :build do
  puts "\n=== Building Jekyll site ===\n"
  sh "bundle exec jekyll build"
end

desc "Serve Jekyll site (development)"
task :serve do
  sh "bundle exec jekyll serve"
end

desc "Validate all posts have correct front matter"
task :validate_posts do
  puts "\n=== Validating Posts ===\n"
  ruby "_test/post_validator.rb"
end

desc "Check all internal links (requires build)"
task :check_links do
  puts "\n=== Checking Links ===\n"
  begin
    sh "bundle exec htmlproofer _site/ --assume-extension --disable-external"
  rescue
    puts "html-proofer unavailable, using fallback link checker..."
    ruby "_test/link_checker.rb"
  end
end

desc "Run content validation only (no build)"
task :"test:content" do
  puts "\n=== Running Content Validation ===\n"
  ruby "_test/post_validator.rb"
end

desc "Run build validation only"
task :"test:build" => :build do
  puts "\n=== Build validation passed ===\n"
end

desc "Run all link checks (requires build first)"
task :"test:links" => :build do
  Rake::Task[:check_links].invoke
end

desc "Run all tests (build + content + links)"
task :test do
  puts "\n" + "="*50
  puts "Running WriterBlog Test Suite"
  puts "="*50 + "\n"

  puts "\n[1/3] Building site..."
  begin
    Rake::Task[:build].invoke
  rescue
    puts "\n✗ BUILD FAILED"
    exit 1
  end
  puts "✓ Build successful\n\n"

  puts "[2/3] Validating posts..."
  begin
    sh "ruby _test/post_validator.rb"
  rescue
    puts "\n✗ POST VALIDATION FAILED"
    exit 1
  end
  puts "✓ Post validation complete\n\n"

  puts "[3/3] Checking links..."
  begin
    Rake::Task[:check_links].invoke
  rescue
    puts "\n✗ LINK CHECK FAILED"
    exit 1
  end
  puts "✓ Link check complete\n\n"

  puts "="*50
  puts "All tests passed!"
  puts "="*50 + "\n"
end

task :default => :test
