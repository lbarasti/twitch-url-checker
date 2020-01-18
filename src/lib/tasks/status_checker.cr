require "http/client"
require "../logging"

module StatusChecker
  extend Logging

  record Success, url : String, status_code : Int32, response_time : Time::Span
  record Failure, url : String, err : Exception
  private def self.get_status(url : String)
    start_time = Time.utc
    uri = URI.parse(url)
    client = HTTP::Client.new uri
    client.connect_timeout = 0.2.seconds
    client.read_timeout = 1.seconds
    res = client.get "/"
    Success.new(url, res.status_code, Time.utc - start_time)
  rescue e : Errno | Socket::Addrinfo::Error | OpenSSL::SSL::Error | IO::Timeout
    logger.error(url + " " + e.to_s)
    Failure.new(url, e)
  end

  def self.run(url : String)
    get_status(url)
  end
end