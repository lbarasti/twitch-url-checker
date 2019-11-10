require "../stats"

module StatsLogger
  extend Logging

  def self.run(url_status_stream, stats_stream)
    spawn(name: "stats_logger") do
      logger.info("Starting")
      stats = Stats.new
      loop do
        url, result = url_status_stream.receive
        case result
        when Int32
          if result < 400
            stats.log_success(url)
          else
            stats.log_failure(url)
          end
        when Exception
          stats.log_failure(url)
        end
        
        data = stats.map { |k, v|
          {k, v}
        }
        stats_stream.send data
      end
    end
  end
end