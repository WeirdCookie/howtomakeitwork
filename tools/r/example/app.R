library(plumber)

tool <- Sys.getenv("TOOL_NAME", "r-tool")
port <- as.integer(Sys.getenv("PORT", "8087"))

#* @get /health
function() {
  list(status = "ok", tool = tool, language = "r")
}

#* @get /
function() {
  list(message = "R Tool läuft!", tool = tool)
}

#* @post /api/echo
function(req) {
  data <- jsonlite::fromJSON(req$postBody)
  list(input = data, language = "r")
}

pr <- plumb("app.R")
pr$run(host = "0.0.0.0", port = port)