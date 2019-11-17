require "./logging"
module ConcurrencyUtil
  extend Logging

  def timer(time : Time::Span)
    Channel(Nil).new(1).tap { |ch|
      spawn(name: "timer") do
        sleep time
        ch.send(nil)
      end
    }
  end

  def every(period : Time::Span,
    interrupt : Channel(Nil),
    &block : -> Enumerable(T)) forall T
    Channel(T).new.tap { |out_stream|
      spawn(name: "generator") do
        loop do
          select
          when timer(period).receive
            block.call >> out_stream
          when interrupt.receive
            ConcurrencyUtil.logger.info("shutting down")
            break
          end
        end
      ensure
        out_stream.close
      end
    }
  end
end

module Enumerable(T)
  def >>(channel : Channel(T))
    spawn do
      each { |value|
        channel.send value
      }
    end
  end
end