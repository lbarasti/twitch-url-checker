require "http/client"
require "yaml"
require "tablo"

get_urls = -> {
  file_lines = File.read("./urls.yml")
  YAML.parse(file_lines)["urls"].as_a.map(&.as_s)
}

get_status = ->(url : String) {
  begin
    res = HTTP::Client.get url
    {url, res.status_code}
  rescue e : Errno | Socket::Addrinfo::Error
    {url, e}
  ensure
  end
}

url_stream = Channel(String).new
result_stream = Channel({String, Int32 | Exception}).new

spawn do
  get_urls.call.each { |url|
    url_stream.send url
  }
end

2.times {
  spawn do
    loop do
      url = url_stream.receive
      result = get_status.call(url)
      
      result_stream.send result
    end
  end
}

stats = Hash(String, {success: Int32, failure: Int32}).new({success: 0, failure: 0})
loop do
  url, result = result_stream.receive
  current_value = stats[url]
  case result
  when Int32
    if result < 400
      stats[url] = {
        success: current_value["success"] + 1,
        failure: current_value["failure"]
      }
    else
      stats[url] = { # TODO: refactor to avoid repetition
        success: current_value["success"],
        failure: current_value["failure"] + 1
      }
    end
  when Exception
    stats[url] = {
      success: current_value["success"],
      failure: current_value["failure"] + 1
    }
  end
  data = stats.map { |k, v|
    [k, v["success"], v["failure"]]
  }
  table = Tablo::Table.new(data) do |t| # TODO: extract to function
    t.add_column("Url", width: 24) { |n| n[0] }
    t.add_column("Success") { |n| n[1] }
    t.add_column("Failure") { |n| n[2] }
  end
  puts table
end

# url_generator -> [url] -> worker_0 -> [{url, result}] -> printer
#                        \_ worker_1 _/ 

puts "goodbye"