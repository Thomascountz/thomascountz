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
    abort("#{filename} already exists!")
  end

  puts "Creating new post: #{filename}"
  front_matter = {
    'layout' => 'post',
    'title' => title,
    'date' => Date.today.to_s
  }

  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
end

desc 'Create a new memo'
task :memo do
  title = ENV['title'] || abort('Please provide a title with title=')
  slug = slugify(title)
  date = Date.today.strftime('%Y-%m-%d')
  filename = File.join('_memos', "#{date}-#{slug}.md")

  if File.exist?(filename)
    abort("#{filename} already exists!")
  end

  puts "Creating new memo: #{filename}"
  front_matter = {
    'layout' => 'memo',
    'title' => title,
    'date' => Date.today.to_s,
    'tags' => ["memo"].append(ENV['tags']&.split(',')),
  }

  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
end
