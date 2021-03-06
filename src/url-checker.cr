require "diagnostic_logger"
require "./lib/config"
require "./lib/concurrency_util"
require "./lib/tasks/*"
require "./lib/server/stats_store"

# url_generator -> [url] -> status_checker_0 -> [status] -> mvg_avg -> [enriched_status]
#                        \_ status_checker_1 _/          \_  alert /         |
#                                                                          stats_writer
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

status_stream = url_stream.map(workers: config.workers) { |url|
  StatusChecker.run(url)
}

success_stream, failure_stream = status_stream.partition { |v|
  v.is_a?(StatusChecker::Success) && v.status_code < 400
}

enriched_success_stream = AvgResponseTime.run(success_stream, width: 5)
enriched_failure_stream = Alerting.run(failure_stream, failures: 3, time_range: 10.seconds)

stats_store = StatsStore.new

writer_done = StatsWriter.run(enriched_success_stream | enriched_failure_stream, stats_store)

stats_stream = every(3.seconds, name: "stats_watcher", interrupt: interrupt_ui) {
  logger.info("reading from stats store")
  [stats_store.get]
}

printer_done = Printer.run(stats_stream)

printer_done.receive?
writer_done.receive?
puts stats_store.get
puts "\rgoodbye"