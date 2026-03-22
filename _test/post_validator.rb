require 'yaml'
require 'find'
require 'pathname'

class PostValidator
  REQUIRED_FRONT_MATTER = %w[title date layout]
  POST_NAME_REGEX = /^\d{4}-\d{2}-\d{2}-[a-z0-9-]+\.(md|markdown)$/i
  VALID_LAYOUTS = %w[post page].freeze

  attr_reader :errors, :warnings

  def initialize(posts_dir)
    @posts_dir = posts_dir
    @errors = []
    @warnings = []
  end

  def validate_all
    return @errors << "Posts directory does not exist: #{@posts_dir}" unless Dir.exist?(@posts_dir)

    post_files = Dir.glob(File.join(@posts_dir, '*'))
    if post_files.empty?
      @warnings << "No post files found in #{@posts_dir}"
      return
    end

    post_files.each { |file| validate_post(file) }
  end

  def validate_post(file_path)
    filename = File.basename(file_path)
    content = File.read(file_path)

    validate_filename(filename, file_path)
    validate_front_matter(content, filename)
  end

  def validate_filename(filename, file_path)
    unless POST_NAME_REGEX.match?(filename)
      @errors << "Invalid post filename format: #{filename}"
      @errors << "  Expected: YYYY-MM-DD-title.md, got: #{filename}"
    end

    expected_date = extract_date_from_filename(filename)
    frontmatter_date = extract_date_from_frontmatter(file_path)

    if expected_date && frontmatter_date && expected_date != frontmatter_date
      @errors << "Date mismatch in #{filename}: filename says #{expected_date}, front matter says #{frontmatter_date}"
    end
  end

  def validate_front_matter(content, filename)
    front_matter = parse_front_matter(content)
    return @errors << "Could not parse front matter in #{filename}" unless front_matter

    REQUIRED_FRONT_MATTER.each do |key|
      unless front_matter.key?(key)
        @errors << "Missing required front matter '#{key}' in #{filename}"
      end
    end

    if front_matter['published'] == false
      @warnings << "Post is unpublished: #{filename}"
    end

    if front_matter['date'].is_a?(String)
      begin
        Date.parse(front_matter['date'])
      rescue ArgumentError
        @errors << "Invalid date format in #{filename}: #{front_matter['date']}"
      end
    end

    if front_matter['layout'] && !VALID_LAYOUTS.include?(front_matter['layout'])
      @warnings << "Unusual layout '#{front_matter['layout']}' in #{filename}"
    end
  end

  private

  def parse_front_matter(content)
    if content.start_with?('---')
      parts = content.split('---', 3)
      return nil unless parts.length >= 3
      YAML.safe_load(parts[1], permitted_classes: [Date, Time])
    else
      nil
    end
  rescue Psych::SyntaxError => e
    @errors << "YAML syntax error: #{e.message}"
    nil
  rescue ArgumentError => e
    @errors << "Date parsing error: #{e.message}"
    nil
  end

  def extract_date_from_filename(filename)
    match = filename.match(/^(\d{4})-(\d{2})-(\d{2})/)
    return nil unless match
    Date.new(match[1].to_i, match[2].to_i, match[3].to_i)
  rescue ArgumentError
    nil
  end

  def extract_date_from_frontmatter(file_path)
    content = File.read(file_path)
    front_matter = parse_front_matter(content)
    return nil unless front_matter && front_matter['date']

    date_str = front_matter['date'].to_s
    Date.parse(date_str)
  rescue ArgumentError, NoMethodError
    nil
  end

  def self.run(posts_dir = '_posts')
    validator = new(posts_dir)
    validator.validate_all

    puts "\n=== Post Validation Results ===\n\n"

    unless validator.errors.empty?
      puts "ERRORS (#{validator.errors.length}):"
      validator.errors.each { |e| puts "  ✗ #{e}" }
    end

    unless validator.warnings.empty?
      puts "\nWARNINGS (#{validator.warnings.length}):"
      validator.warnings.each { |w| puts "  ⚠ #{w}" }
    end

    if validator.errors.empty? && validator.warnings.empty?
      puts "✓ All posts passed validation!"
    end

    puts "\n"
    validator.errors.empty?
  end
end

if __FILE__ == $PROGRAM_NAME
  posts_dir = ARGV[0] || '_posts'
  success = PostValidator.run(posts_dir)
  exit(success ? 0 : 1)
end
