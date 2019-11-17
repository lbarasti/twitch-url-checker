require "logger"
require "diagnostic_logger"

module Logging
  macro extended
    def self.logger
      @@logger ||= DiagnosticLogger.new({{@type.stringify}})
    end
  end
end
