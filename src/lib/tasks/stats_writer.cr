require "../stats"

module StatsWriter
  extend Logging

  def self.run(url_status_stream, stats_store : StatsStore)
    spawn(name: "stats_writer") do
      loop do
        url, result = url_status_stream.receive
        case result
        when Int32
          if result < 400
            stats_store.log_success(url)
          else
            stats_store.log_failure(url)
          end
        when Exception
          stats_store.log_failure(url)
        end
      rescue Channel::ClosedError
        logger.info("Shutting down")
        break
      end
    end
  end
end