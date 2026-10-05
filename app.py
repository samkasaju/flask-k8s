from flask import Flask, render_template
import os

app = Flask(__name__)


@app.route("/")
def home():
    return render_template(
        "index.html",
        environment=os.getenv("APP_ENV", "local"),
        message=os.getenv("APP_MESSAGE", "Hello from Flask - CI/CD is working!"),
    )


@app.route("/health")
def health():
    return "ok", 200


@app.route("/cpu")
def cpu():
    return str(sum(i * i for i in range(5_000_000)))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
