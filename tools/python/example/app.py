from flask import Flask, jsonify, request
import os

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify(status="ok", tool=os.environ.get('TOOL_NAME', 'python-tool'), language="python")

@app.route('/')
def index():
    return jsonify(message="Python Tool läuft!", tool=os.environ.get('TOOL_NAME', 'python-tool'))

@app.route('/api/echo', methods=['POST'])
def echo():
    data = request.get_json() or {}
    return jsonify(input=data, language="python")

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)