require 'date'
require 'fileutils'
require 'yaml'

def slugify(title)
  title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
end

desc 'Create a new draft (title= required, tags= optional comma-separated)'
task :post do
  title = ENV['title'] || abort('Please provide a title with title=')
  tags = ENV['tags'] ? ENV['tags'].split(',').map(&:strip) : []
  slug = slugify(title)
  date = Date.today.strftime('%Y-%m-%d')
  filename = File.join('_drafts', "#{date}-#{slug}.md")

  if File.exist?(filename)
    abort("Error: #{filename} already exists!")
  end

  puts "Creating new draft: #{filename}"
  front_matter = {
    'layout' => 'post',
    'title' => title,
    'subtitle' => '',
    'date' => Date.today.to_s,
    'description' => '',
    'tags' => tags
  }

  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
  puts "Draft created successfully!"
end

desc 'Publish a draft to _posts/ (file= required)'
task :publish do
  file = ENV['file'] || abort('Please provide a draft with file=')
  unless File.exist?(file)
    abort("Error: #{file} not found!")
  end

  basename = File.basename(file)
  dest = File.join('_posts', basename)

  if File.exist?(dest)
    abort("Error: #{dest} already exists!")
  end

  FileUtils.mv(file, dest)
  puts "Published: #{dest}"
end

def collect_posts_with_tags
  Dir.glob('_posts/*.md').map do |file|
    content = File.read(file)
    if content =~ /\A---\s*\n(.*?)\n---/m
      front_matter = YAML.safe_load($1, permitted_classes: [Date])
      { file: file, tags: (front_matter['tags'] || []).flatten.compact }
    else
      { file: file, tags: [] }
    end
  end
end

desc 'List tags (tag= filter, rake tags[alpha] to sort, rake tags[,all] to expand)'
task :tags, [:sort, :expand] do |t, args|
  alphabetical = args[:sort] == 'alpha'
  show_all = args[:expand] == 'all'

  posts = collect_posts_with_tags
  tag_counts = posts.flat_map { |p| p[:tags] }.tally
  tag_counts = alphabetical ? tag_counts.sort_by { |tag, _| tag } : tag_counts.sort_by { |_, count| -count }

  if ENV['tag']
    tag = ENV['tag']
    matching_posts = posts.select { |p| p[:tags].include?(tag) }

    if matching_posts.empty?
      puts "No posts found with tag '#{tag}'"
    else
      puts "#{tag} (#{matching_posts.count})"
      matching_posts.each { |p| puts "  - #{p[:file]}" }
    end
  elsif show_all
    tag_counts.each do |tag, count|
      puts "#{tag} (#{count})"
      posts.select { |p| p[:tags].include?(tag) }.each { |p| puts "  - #{p[:file]}" }
    end
  else
    puts "Tags (#{tag_counts.count})"
    tag_counts.each { |tag, count| puts "  #{count.to_s.rjust(3)}  #{tag}" }
  end
end
