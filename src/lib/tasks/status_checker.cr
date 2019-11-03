require "http/client"

module StatusChecker
  private def self.get_status(url : String)
    res = HTTP::Client.get url
    {url, res.status_code}
  rescue e : Errno | Socket::Addrinfo::Error | OpenSSL::SSL::Error
    {url, e}
  end

  def self.run(url_stream, url_status_stream)
    spawn do
      loop do
        url = url_stream.receive
        result = get_status(url)
        
        url_status_stream.send result
      end
    end
  end
end