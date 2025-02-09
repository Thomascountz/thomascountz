require "fileutils"
require "yaml"

# Converts a title to a slug format
def slugify(title)
  title.downcase.strip.tr(" ", "-").gsub(/[^\w-]/, "")
end

# Extracts the title from the filename by removing the date and file extension, and converting underscores or hyphens to spaces
def extract_title_from_filename(filename)
  File.basename(filename, ".*")
    .sub(/^\d{4}-\d{2}-\d{2}-/, "")
    .gsub(/[_-]/, " ")
    .split
    .map(&:capitalize)
    .join(" ")
end

def extract_image_tags(content)
  image_tag_pattern = /!\[(.*?)\]\((.*?)\)|!\[\[(.*?)\]\]/
  content.scan(image_tag_pattern)
end

def copy_image(source_image_path, dest_image_path)
  if File.exist?(source_image_path)
    FileUtils.cp(source_image_path, dest_image_path)
    true
  else
    false
  end
end

def update_image_paths(content, source_dir, dest_dir)
  image_tag_pattern = /!\[(.*?)\]\((.*?)\)|!\[\[(.*?)\]\]/

  content.gsub(image_tag_pattern) do |match|
    alt_text = $1 || $3
    image_path = $2 || $3

    if image_path.nil? || image_path.empty?
      puts "Warning: Image path is missing in the tag: #{match}"
      next match
    end

    # Handle cases where the image markdown contains a width specification
    # e.g. ![[image.png|600]]
    image_path = image_path.split("|")[0]
    alt_text = alt_text.split("|")[0]

    source_image_path = File.join(source_dir, image_path)
    dest_image_path = File.join(dest_dir, File.basename(image_path))

    if copy_image(source_image_path, dest_image_path)
      "![#{alt_text}](/#{dest_image_path})"
    else
      puts "Warning: Image file #{source_image_path} does not exist."
      match
    end
  end
end

def copy_images_and_update_paths(content, source_dir, dest_dir)
  update_image_paths(content, source_dir, dest_dir)
end

# Reads the content of the file and removes any existing front matter
def read_content_without_front_matter(filepath)
  content = File.read(filepath)
  content.sub(/\A---.*?---\s*/m, "")
end

# Creates the front matter for the new memo file
def create_front_matter(title, ctime)
  {
    "layout" => "memo",
    "title" => title,
    "date" => ctime.to_s,
    "tags" => ["memo"]
  }
end

# Writes the new memo file with the updated content and front matter
def write_memo_file(filename, front_matter, content)
  File.open(filename, "w") do |file|
    file.puts(front_matter.to_yaml)
    file.puts("---")
    file.puts(content)
  end
end
