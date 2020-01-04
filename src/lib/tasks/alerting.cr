module Alerting
  record StatusWithAlert, status : StatusChecker::Success | StatusChecker::Failure, alert_on : Bool

  def self.run(failure_stream, failures : Int32, time_range : Time::Span) : Channel(StatusWithAlert)
    Channel(StatusWithAlert).new.tap { |out_stream|
      spawn do
        most_recent = Hash(String,Deque(Time)).new { |hash, key|
          hash[key] = Deque(Time).new(failures)
        }
        loop do
          status = failure_stream.receive
          most_recent_for_url = most_recent[status.url]
          most_recent_for_url.shift? if most_recent_for_url.size >= failures
          most_recent_for_url.push Time.utc

          alert_on = (most_recent_for_url.size >= failures) &&
            (most_recent_for_url.last - most_recent_for_url.first < time_range)

          out_stream.send(StatusWithAlert.new status, alert_on)
        end
      rescue Channel::ClosedError
        # log
      ensure
        out_stream.close
      end
    }
  end
end