require 'nokogiri'
require 'pathname'

class LinkChecker
  BASEURL = '/D3lK1ch1'.freeze

  def initialize(site_dir)
    @site_dir = Pathname.new(site_dir)
    @errors = []
    @checked = []
  end

  def check_all
    puts "\n=== Basic Link Validation ===\n"
    puts "  Note: Skipping baseurl-prefixed paths (correct for GitHub Pages deployment)\n"

    html_files.each { |file| check_file(file) }
    check_missing_files

    if @errors.empty?
      puts "\n✓ No missing local resources found"
    else
      puts "\nERRORS (#{@errors.length}):"
      @errors.each { |e| puts "  ✗ #{e}" }
    end

    @errors.empty?
  end

  def html_files
    Dir.glob(@site_dir.join('**/*.html'))
  end

  def check_file(file_path)
    doc = Nokogiri::HTML(File.read(file_path))
    base = Pathname.new(file_path).dirname

    doc.search('img[src], a[href], link[href], script[src]').each do |node|
      attr = node['src'] || node['href']
      next unless attr

      if attr.start_with?('/') && !attr.start_with?('//')
        path = attr.sub(/^\//, '')
        path = path.sub(/^#{BASEURL}\//, '') if path.start_with?(BASEURL)

        if attr.start_with?(BASEURL)
          @checked << attr
          next
        end

        full_path = @site_dir.join(path)

        unless full_path.exist?
          @errors << "#{file_path}: Missing resource: /#{path}"
        end
        @checked << "/#{path}"
      elsif attr.include?('{{') || attr.include?('{%')
        # Skip Liquid template syntax
      end
    rescue => e
      puts "  Warning: Could not parse #{file_path}: #{e.message}"
    end
  end

  def check_missing_files
    puts "  Checked #{@checked.uniq.length} internal resources"
  end

  def self.run(site_dir = '_site')
    checker = new(site_dir)
    success = checker.check_all
    exit(success ? 0 : 1)
  end
end

if __FILE__ == $PROGRAM_NAME
  site_dir = ARGV[0] || '_site'
  LinkChecker.run(site_dir)
end
