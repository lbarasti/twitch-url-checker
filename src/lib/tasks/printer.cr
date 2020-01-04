require "tablo"
require "../logging"

module Printer
  extend Logging

  def self.run(stats_stream)
    Channel(Nil).new.tap { |done|
      spawn do
        loop do
          data = stats_stream.receive.map { |v|
            failure_with_alert = "#{v[:failure]}#{v[:alert_on] ? "*" : ""}"
            [v[:url], v[:success], failure_with_alert, v[:avg_response_time].total_milliseconds]
          }
          table = Tablo::Table.new(data) do |t|
            t.add_column("Url", width: 24) { |n| n[0] }
            t.add_column("Success") { |n| n[1] }
            t.add_column("Failure") { |n| n[2] }
            t.add_column("Avg RT") { |n| n[3] }
          end
          puts table
        end
      rescue Channel::ClosedError
        logger.info("input stream was closed")
      ensure
        done.close
      end
    }
  end
end