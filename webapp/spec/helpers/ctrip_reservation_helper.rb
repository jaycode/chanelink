def create_log(filename, path, request, response)
  filepath = Rails.root.join('tmp', filename)
  File.open(filepath, "w+") do |f|
    f.write "Path: #{path}\n"
    f.write "Request:\n#{request}\n"
    f.write "Response:\n#{response}"
  end
  puts "File created at #{filepath}"
end