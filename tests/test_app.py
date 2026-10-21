from app.main import app

def client():
    app.config["TESTING"] = True
    return app.test_client()

def test_health_returns_ok():
    res = client().get("/health")
    assert res.status_code == 200
    assert res.get_json()["status"] == "ok"

def test_items_returns_list():
    res = client().get("/items")
    assert res.status_code == 200
    assert len(res.get_json()) == 2

def test_version_defaults_to_dev():
    res = client().get("/version")
    assert res.get_json()["version"] == "dev"
