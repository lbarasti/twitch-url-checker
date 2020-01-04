module AvgResponseTime
  extend Logging
  record SuccessWithAvgRT, status : StatusChecker::Success, avg_rt : Time::Span
  def self.run(success_stream, width : Int32) : Channel(SuccessWithAvgRT)
    Channel(SuccessWithAvgRT).new.tap { |out_stream|
      spawn do
        most_recent = Hash(String, Deque(Time::Span)).new { |hash, key|
          hash[key] = Deque(Time::Span).new(width)
        }
        loop do
          status = success_stream.receive.as(StatusChecker::Success)
          most_recent_for_url = most_recent[status.url]
          most_recent_for_url.shift? if most_recent_for_url.size >= width
          most_recent_for_url.push status.response_time
          mvg_avg = most_recent_for_url.reduce {|a,b| a + b} / most_recent_for_url.size
          AvgResponseTime.logger.debug(status.url + ": " + most_recent_for_url.to_s + " " + mvg_avg.to_s)
          out_stream.send(SuccessWithAvgRT.new(status, mvg_avg))
        end
      rescue Channel::ClosedError
        AvgResponseTime.logger.info("Shutting down")
      ensure
        out_stream.close
      end
    }
  end
end