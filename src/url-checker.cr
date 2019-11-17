require "diagnostic_logger"
require "./lib/config"
require "./lib/concurrency_util"
require "./lib/tasks/status_checker"
require "./lib/tasks/stats_logger"
require "./lib/tasks/printer"

# url_generator -> [url] -> status_checker_0 -> [{url, result}] -> stats_logger -> [stats::info] -> printer
#                        \_ status_checker_1 _/
include ConcurrencyUtil

config = Config.load
logger = DiagnosticLogger.new("main")
interrupt = Channel(Nil).new


Signal::INT.trap do
  logger.info("shutting down")
  interrupt.send nil
end

url_stream = every(config.period, interrupt: interrupt) {
  logger.info("sending urls")
  Config.load.urls
}

result_stream = StatusChecker.run(url_stream, workers: config.workers)

stats_stream = StatsLogger.run(result_stream)

done = Printer.run(stats_stream)

done.receive?
puts "\rgoodbye"