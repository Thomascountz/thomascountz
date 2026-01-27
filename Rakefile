require 'date'
require 'yaml'

def slugify(title)
  title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
end

desc 'Create a new blog post'
task :post do
  title = ENV['title'] || abort('Please provide a title with title=')
  slug = slugify(title)
  date = Date.today.strftime('%Y-%m-%d')
  filename = File.join('_posts', "#{date}-#{slug}.md")

  if File.exist?(filename)
    abort("Error: #{filename} already exists!")
  end

  puts "Creating new post: #{filename}"
  front_matter = {
    'layout' => 'post',
    'title' => title,
    'date' => Date.today.to_s,
    'description' => ''
  }

  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
  puts "Post created successfully!"
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
