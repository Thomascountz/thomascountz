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
    'date' => Date.today.to_s
  }

  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
  puts "Post created successfully!"
end

desc 'Create a new journal'
task :journal do
  title = ENV['title'] || abort('Please provide a title with title=')
  slug = slugify(title)
  date = Date.today.strftime('%Y-%m-%d')
  filename = File.join('_posts', "#{date}-#{slug}.md")

  if File.exist?(filename)
    abort("Error: #{filename} already exists!")
  end

  puts "Creating new journal: #{filename}"
  front_matter = {
    'layout' => 'post',
    'title' => title,
    'date' => Date.today.to_s,
    'tags' => ["journal"].append(ENV['tags']&.split(',')),
  }

  File.open(filename, 'w') do |file|
    file.puts(front_matter.to_yaml)
    file.puts('---')
    file.puts
  end
  puts "Journal created successfully!"
end

# rake copy_journal[<filepath>]
desc 'Copy markdown content to _posts directory'
task :copy_journal do |t, args|
  filepath = ENV['filepath'] || abort('Please provide a filepath with filepath=')
  abort("Error: File #{filepath} does not exist!") unless File.exist?(filepath)

  title = extract_title_from_filename(filepath)
  slug = slugify(title)
  ctime = File.ctime(filepath).strftime('%Y-%m-%d')
  filename = File.join('_posts', "#{ctime}-#{slug}.md")

  abort("Error: #{filename} already exists!") if File.exist?(filename)

  puts "Creating new journal: #{filename}"

  front_matter = create_front_matter(title, File.ctime(filepath))
  content_without_front_matter = read_content_without_front_matter(filepath)

  source_dir = File.dirname(filepath)
  dest_image_dir = './assets/images/journals'
  updated_content = copy_images_and_update_paths(content_without_front_matter, source_dir, dest_image_dir)

  write_journal_file(filename, front_matter, updated_content)
  puts "Journal copied successfully!"
end
