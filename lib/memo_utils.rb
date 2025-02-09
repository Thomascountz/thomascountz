require "fileutils"
require "yaml"

# Converts a title to a slug format
def slugify(title)
  title.downcase.strip.tr(" ", "-").gsub(/[^\w-]/, "")
end

# Extracts the title from the filename by removing the date and file extension, and converting underscores or hyphens to spaces
def extract_title_from_filename(filename)
  File.basename(filename, File.extname(filename)).split("-", 3).last.gsub(/[_-]/, " ").split.map(&:capitalize).join(" ")
end

# Copies images referenced in the markdown content to the destination directory and updates the paths in the content
def copy_images_and_update_paths(content, source_dir, dest_dir)
  content.gsub(/!\[.*?\]\((.*?)\)/) do |match|
    image_path = $1
    source_image_path = File.join(source_dir, image_path)
    if File.exist?(source_image_path)
      dest_image_path = File.join(dest_dir, File.basename(image_path))
      FileUtils.cp(source_image_path, dest_image_path)
      "![#{File.basename(image_path)}](#{dest_image_path})"
    else
      puts "Warning: Image file #{source_image_path} does not exist."
      match
    end
  end
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
