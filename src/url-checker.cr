require "./lib/concurrency_util"
require "./lib/tasks/url_generator"
require "./lib/tasks/status_checker"
require "./lib/tasks/stats_logger"
require "./lib/tasks/printer"

# url_generator -> [url] -> status_checker_0 -> [{url, result}] -> stats_logger -> [stats::info] -> printer
#                        \_ status_checker_1 _/

WORKERS = 2
url_stream = Channel(String).new
result_stream = Channel({String, Int32 | Exception}).new
stats_stream = Channel(Array({String, Stats::Info})).new

every(2.seconds) {
  UrlGenerator.run("./urls.yml", url_stream)
}

WORKERS.times {
  StatusChecker.run(url_stream, result_stream)
}

StatsLogger.run(result_stream, stats_stream)

Printer.run(stats_stream)

sleep
puts "goodbye"