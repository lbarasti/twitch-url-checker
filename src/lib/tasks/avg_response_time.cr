module AvgResponseTime
  def self.run(success_stream, width : Int32) : Channel({StatusChecker::Success, Time::Span})
    Channel({StatusChecker::Success, Time::Span}).new.tap { |out_stream|
      spawn do
        most_recent = Deque(Time::Span).new(width)
        loop do
          status = success_stream.receive.as(StatusChecker::Success)
          most_recent.shift?
          most_recent.push status.response_time
          mvg_avg = most_recent.reduce(&.+) / width
          out_stream.send({status, mvg_avg})
        end
      rescue Channel::ClosedError
        # log
      ensure
        out_stream.close
      end
    }
  end
end