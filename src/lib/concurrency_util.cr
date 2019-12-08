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
    interrupt : Channel(Nil) = Channel(Nil).new,
    name : String = "generator",
    &block : -> Enumerable(T)) forall T
    Channel(T).new.tap { |out_stream|
      spawn(name: name) do
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

abstract class Channel(T)
  extend Logging
  def map(workers : Int32 = 1, &block : T -> K) : Channel(K) forall K
    countdown = Channel(Nil).new(workers)
    Channel(K).new.tap { |output_stream|
      spawn(name: "supervisor") do
        workers.times {
          countdown.receive
        }
        output_stream.close
      end
      workers.times { |w_i|
        spawn(name: "worker_#{w_i}") do
          loop do
            output_stream.send block.call(self.receive)
          end
        rescue Channel::ClosedError
          Channel.logger.info("input stream was closed")
        ensure
          countdown.send nil
        end
      }
    }
  end

  def partition(&predicate : T -> Bool) : {Channel(T), Channel(T)}
    {Channel(T).new, Channel(T).new}.tap { |pass, fail|
      spawn do
        loop do
          value = self.receive
          predicate.call(value) ? pass.send(value) : fail.send(value)
        end
      rescue Channel::ClosedError
        pass.close; fail.close
      end
    }
  end

  def |(other : Channel(K)) : Channel(T | K)  forall K
    Channel(K | T).new.tap { |output_stream|
      spawn do
        loop do
          output_stream.send Channel.receive_first(self, other)
        end
      rescue Channel::ClosedError
        output_stream.close # TODO: only close the downstream channel once both the input streams have been closed
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