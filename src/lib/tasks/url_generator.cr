require "yaml"

module UrlGenerator
  private def self.get_urls(config_file)
    file_lines = File.read(config_file)
    YAML.parse(file_lines)["urls"].as_a.map(&.as_s)
  end
  
  def self.run(config_file, url_stream)
    spawn do
      get_urls(config_file).each { |url|
        url_stream.send url
      }
    end
  end
end