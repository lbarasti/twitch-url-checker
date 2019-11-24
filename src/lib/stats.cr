class Stats
  alias Info = NamedTuple(url: String, success: Int32, failure: Int32)
  include Enumerable({String, Info})
  delegate each, to: @hash
  delegate values, to: @hash
  def initialize
    @hash = Hash(String, Info).new { |hash, key|
      {url: key, success: 0, failure: 0}
    }
  end
  def log_success(url : String)
    current = @hash[url][:success]
    @hash[url] = @hash[url].merge({
      success: current + 1
    })
  end
  def log_failure(url : String)
    current = @hash[url][:failure]
    @hash[url] = @hash[url].merge({
      failure: current + 1
    })
  end
end