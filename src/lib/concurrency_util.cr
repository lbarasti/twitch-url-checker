def every(period : Time::Span, &block : -> T) forall T
  spawn do
    loop do
      block.call
      sleep period
    end
  end
end