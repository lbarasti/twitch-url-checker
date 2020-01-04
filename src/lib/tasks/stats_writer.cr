require "../stats"

module StatsWriter
  extend Logging

  def self.run(url_status_stream, stats_store : StatsStore)
    Channel(Nil).new.tap { |done|
      spawn(name: "stats_writer") do
        loop do
          case received = url_status_stream.receive
          when AvgResponseTime::SuccessWithAvgRT
            status_obj, avg_response_time = received.status, received.avg_rt
            stats_store.log_success(status_obj.url, avg_response_time)
          when Alerting::StatusWithAlert
            stats_store.log_failure(received.status.url, received.alert_on)
          end
        end
      rescue Channel::ClosedError
        logger.info("input stream was closed")
      ensure
        done.close
      end
    }
  end
end