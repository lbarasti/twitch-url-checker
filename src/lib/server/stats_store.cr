require "../stats"
require "../logging"

class StatsStore
  extend Logging
  record LogSuccess, url : String
  record LogFailure, url : String
  record Get, return_channel : Channel(Array(Stats::Info))

  @request = Channel(LogSuccess | LogFailure | Get).new
  @stats = Stats.new
  def initialize
    spawn(name: "stats_store") do
      loop do
        case req = @request.receive
        when LogSuccess
          @stats.log_success(req.url)
        when LogFailure
          @stats.log_failure(req.url)
        when Get
          req.return_channel.send @stats.values
        end
      end
    end
  end

  def log_success(url : String)
    @request.send(LogSuccess.new(url))
  end
  def log_failure(url : String)
    @request.send(LogFailure.new(url))
  end
  def get : Array(Stats::Info)
    return_channel = Channel(Array(Stats::Info)).new(1)
    @request.send(Get.new(return_channel))
    return_channel.receive
  end
end