require "yaml"

struct Time::Span
  def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Time::Span
    unless node.is_a?(YAML::Nodes::Scalar)
      node.raise "Expected scalar, not #{node.class}"
    end

    node.value.to_f.seconds
  end
end


class Config
  YAML.mapping(
    workers: Int32,
    period: {
      converter: Time::Span,
      type: Time::Span
    },
    urls: Array(String)
  )
  
  def self.load(config : String = File.read("config.yml"))
    Config.from_yaml(config)
  end
end