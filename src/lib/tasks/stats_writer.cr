require "../stats"

module StatsWriter
  extend Logging

  def self.run(url_status_stream, stats_store : StatsStore)
    spawn(name: "stats_writer") do
      loop do
        case received = url_status_stream.receive
        when {StatusChecker::Success, Time::Span} # TODO: turn tuple into a type, so that we don't have to make assumptions about the status code of the response
          status_obj, avg_response_time = received.as({StatusChecker::Success, Time::Span})
          stats_store.log_success(status_obj.url, avg_response_time)
        when StatusChecker::Failure, StatusChecker::Success
          stats_store.log_failure(received.url)
        end
      rescue Channel::ClosedError
        logger.info("Shutting down")
        break
      end
    end
  end
end