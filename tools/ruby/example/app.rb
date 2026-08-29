require 'webrick'
require 'json'

tool = ENV['TOOL_NAME'] || 'ruby-tool'
port = (ENV['PORT'] || 8085).to_i

server = WEBrick::HTTPServer.new(Port: port, Logger: WEBrick::Log.new("/dev/null"), AccessLog: [])

server.mount_proc '/health' do |req, res|
  res['Content-Type'] = 'application/json'
  res.body = { status: 'ok', tool: tool, language: 'ruby' }.to_json
end

server.mount_proc '/' do |req, res|
  res['Content-Type'] = 'application/json'
  res.body = { message: 'Ruby Tool läuft!', tool: tool }.to_json
end

server.mount_proc '/api/echo' do |req, res|
  data = JSON.parse(req.body || '{}')
  res['Content-Type'] = 'application/json'
  res.body = { input: data, language: 'ruby' }.to_json
end

trap('INT') { server.shutdown }
trap('TERM') { server.shutdown }

puts "Ruby tool starting on port #{port}"
server.start