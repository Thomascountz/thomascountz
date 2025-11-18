require 'date'
require 'yaml'
require_relative 'lib/memo_utils'

def slugify(title)
  title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
end

def write_file_with_front_matter(filename, front_matter)
  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
end

def load_front_matter_from_content(content)
  if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
    yaml_content = $1.strip
    return {} if yaml_content.empty?
    begin
      YAML.safe_load(yaml_content, permitted_classes: [Date])
    rescue Psych::SyntaxError => e
      warn "YAML syntax error: #{e.message}"
      {}
    end
  else
    {}
  end
end

def update_tags_from_front_matter(front_matter, tags)
  return unless front_matter && front_matter['tags']
  Array(front_matter['tags']).each { |tag| tags[tag] += 1 if tag }
end

desc 'Create a new blog post'
task :post do
  title = ENV['title'] || abort('Please provide a title with title=')
  slug = slugify(title)
  date = Date.today.strftime('%Y-%m-%d')
  filename = File.join('_posts', "#{date}-#{slug}.md")

  abort("Error: #{filename} already exists!") if File.exist?(filename)

  puts "Creating new post: #{filename}"
  front_matter = {
    'layout' => 'post',
    'title'  => title,
    'date'   => Date.today.to_s
  }
  write_file_with_front_matter(filename, front_matter)
  puts "Post created successfully!"
end

desc 'Create a new memo'
task :memo do
  title = ENV['title'] || abort('Please provide a title with title=')
  slug = slugify(title)
  date = Date.today.strftime('%Y-%m-%d')
  filename = File.join('_memos', "#{date}-#{slug}.md")

  abort("Error: #{filename} already exists!") if File.exist?(filename)

  puts "Creating new memo: #{filename}"
  extra_tags = ENV['tags'] ? ENV['tags'].split(',') : []
  front_matter = {
    'layout' => 'memo',
    'title'  => title,
    'date'   => Date.today.to_s,
    'tags'   => ['memo'] + extra_tags
  }
  write_file_with_front_matter(filename, front_matter)
  puts "Memo created successfully!"
end

# rake copy_memo[<filepath>]
desc 'Copy markdown content to _memos directory'
task :copy_memo do |t, args|
  filepath = ENV['filepath'] || abort('Please provide a filepath with filepath=')
  abort("Error: File #{filepath} does not exist!") unless File.exist?(filepath)

  title = extract_title_from_filename(filepath)
  slug = slugify(title)
  cdate = File.ctime(filepath).strftime('%Y-%m-%d')
  filename = File.join('_memos', "#{cdate}-#{slug}.md")
  abort("Error: #{filename} already exists!") if File.exist?(filename)

  puts "Creating new memo: #{filename}"
  front_matter = create_front_matter(title, File.ctime(filepath))
  content_without_front_matter = read_content_without_front_matter(filepath)

  source_dir = File.dirname(filepath)
  dest_image_dir = './assets/images/memos'
  updated_content = copy_images_and_update_paths(content_without_front_matter, source_dir, dest_image_dir)

  write_memo_file(filename, front_matter, updated_content)
  puts "Memo copied successfully!"
end

desc "List all tags and usage counts across posts and memos"
task :list_tags do
  tags = Hash.new(0)
  ['_posts', '_memos'].each do |dir|
    Dir.glob(File.join(dir, '*.md')).each do |file|
      content = File.read(file)
      front_matter = load_front_matter_from_content(content)
      update_tags_from_front_matter(front_matter, tags)
    end
  end

  sorted_tags = tags.sort_by { |tag, count| [-count, tag] }
  puts "Tags usage across posts and memos:"
  puts "=" * 40
  sorted_tags.each { |tag, count| puts "#{tag}: #{count}" }
  puts "\nTotal unique tags: #{tags.size}"
end
