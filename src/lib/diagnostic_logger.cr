require "logger"

module Logging
  macro extended
    def self.logger
      @@logger ||= DiagnosticLogger.new({{@type.stringify}})
    end
  end
end

class DiagnosticLogger < Logger
  def initialize(name : String)
    super(File.open("log.txt", "w"))
    @progname = name
    @formatter = Formatter.new do |severity, datetime, progname, message, io|
      io << datetime.to_s("%H:%M:%S") <<
      " [" << severity << "] " <<
      progname << ":" << Fiber.current.name << "> " <<
      message
    end
  end
end