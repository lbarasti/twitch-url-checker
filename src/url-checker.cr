require "diagnostic_logger"
require "./lib/config"
require "./lib/concurrency_util"
require "./lib/tasks/status_checker"
require "./lib/tasks/stats_writer"
require "./lib/tasks/printer"
require "./lib/server/stats_store"

# url_generator -> [url] -> status_checker_0 -> [Stats::Info] -> stats_writer
#                        \_ status_checker_1 _/
#
# stats_watcher -> [Array(Stats::Info)] -> printer
#
include ConcurrencyUtil

config = Config.load
logger = DiagnosticLogger.new("main")
interrupt_url_generation = Channel(Nil).new
interrupt_ui = Channel(Nil).new

Signal::INT.trap do
  logger.info("shutting down")
  interrupt_url_generation.send nil
  interrupt_ui.send nil
end

url_stream = every(config.period, interrupt: interrupt_url_generation) {
  logger.info("sending urls")
  Config.load.urls
}

result_stream = StatusChecker.run(url_stream, workers: config.workers)

stats_store = StatsStore.new

StatsWriter.run(result_stream, stats_store)

stats_stream = every(3.seconds, name: "stats_watcher", interrupt: interrupt_ui) {
  logger.info("reading from stats store")
  [stats_store.get]
}

done = Printer.run(stats_stream)

done.receive?
puts "\rgoodbye"