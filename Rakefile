require 'date'
require 'yaml'
require_relative 'lib/memo_utils'

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
    'date' => Date.today.to_s
  }

  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
  puts "Post created successfully!"
end

desc 'Create a new memo'
task :memo do
  title = ENV['title'] || abort('Please provide a title with title=')
  slug = slugify(title)
  date = Date.today.strftime('%Y-%m-%d')
  filename = File.join('_memos', "#{date}-#{slug}.md")

  if File.exist?(filename)
    abort("Error: #{filename} already exists!")
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
  puts "Memo created successfully!"
end

# rake copy_memo[<filepath>]
desc 'Copy markdown content to _memos directory'
task :copy_memo do |t, args|
  filepath = ENV['filepath'] || abort('Please provide a filepath with filepath=')
  abort("Error: File #{filepath} does not exist!") unless File.exist?(filepath)

  title = extract_title_from_filename(filepath)
  slug = slugify(title)
  ctime = File.ctime(filepath).strftime('%Y-%m-%d')
  filename = File.join('_memos', "#{ctime}-#{slug}.md")

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
