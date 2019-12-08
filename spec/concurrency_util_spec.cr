require "./spec_helper"
include ConcurrencyUtil

describe ConcurrencyUtil do
  describe "every" do
    it "should generate the first value after the given interval" do
      interval = 0.2.seconds
      interrupt = Channel(Nil).new

      start = Time.utc
      out_stream = every(interval, interrupt) {
        (1..5)
      }

      (1..5).each { |i|
        out_stream.receive.should eq(i)
      }
      
      (Time.utc - start).should be_close(interval, interval / 2)
    end
    it "should generate values every given interval" do
      interval = 0.2.seconds
      interrupt = Channel(Nil).new

      start = Time.utc
      out_stream = every(interval, interrupt) {
        (1..5)
      }

      (1..5).each { |i|
        out_stream.receive.should eq(i)
      }
      (1..5).each { |i|
        out_stream.receive.should eq(i)
      }
      
      (Time.utc - start).should be_close(interval * 2, interval / 2)
    end
    it "should close the downstream channel when an interrupt is signaled" do
      interval = 0.2.seconds
      interrupt = Channel(Nil).new

      start = Time.utc
      out_stream = every(interval, interrupt) {
        (1..5)
      }

      (1..5).each { |i|
        out_stream.receive.should eq(i)
      }
      interrupt.send nil
      
      (Time.utc - start).should be_close(interval, interval / 2)
      out_stream.receive?
      out_stream.closed?.should be_true
    end
  end
  describe "Channel#partition" do
    it "should partition values according to a predicate" do
      done = Channel(Nil).new
      ch = Channel(Int32).new
      even, odd = ch.partition(&.even?)
      spawn do
        (1..5).map {|i| ch.send i }
      end

      spawn do
        even.receive.should eq(2)
        even.receive.should eq(4)
        done.send nil
      end
      spawn do
        odd.receive.should eq(1)
        odd.receive.should eq(3)
        odd.receive.should eq(5)
        done.send nil
      end
      2.times { done.receive }
    end
  end
  describe "Channel#map" do
    it "tranforms values coming from a channel" do
      ch = Channel(Int32).new
      squares = ch.map { |i|
        i ** 2
      }
      spawn do
        (1..5).map {|i| ch.send i }
      end

      (1..5).map {|i| i ** 2}.each { |s|
        squares.receive.should eq(s)
      }
    end
    it "can concurrently tranform values coming from a channel" do
      ch = Channel(Int32).new
      squares = ch.map(workers: 4) { |i|
        sleep 0.2 * rand
        i ** 2
      }
      spawn do
        (1..8).map {|i| ch.send i }
      end

      expected_squares = (1..8).map {|i| i ** 2}
      
      8.times {
        s = squares.receive
        expected_squares.should contain(s)
      }
    end
  end
end
