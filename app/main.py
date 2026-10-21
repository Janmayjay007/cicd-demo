import os
from flask import Flask, jsonify

app = Flask(__name__)

ITEMS = [{"id": 1, "name": "laptop"}, {"id": 2, "name": "phone"}]

@app.route("/health")
def health():
    return jsonify(status="ok"), 200

@app.route("/version")
def version():
    return jsonify(version=os.getenv("APP_VERSION", "dev"))

@app.route("/items")
def items():
    return jsonify(ITEMS)

if __name__ == "__main__":
           app.run(host="0.0.0.0", port=8000)
           
