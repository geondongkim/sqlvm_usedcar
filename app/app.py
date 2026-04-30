"""
app/app.py — CarMarket Flask Backend

REST API:
  GET  /health          — DB 연결 헬스체크
  GET  /api/users       — 사용자 목록
  GET  /api/cars        — 차량 목록 (filter: brand, max_price)
  POST /api/cars        — 매물 등록
  POST /api/inquiries   — 문의 등록
  GET  /                — Bootstrap 단일 페이지 UI
"""

import os
from contextlib import contextmanager

import pyodbc
from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request

load_dotenv()

app = Flask(__name__)

DB_SERVER = os.environ.get("DB_SERVER", "localhost")
DB_NAME = os.environ.get("DB_NAME", "CarMarket")
DB_USER = "sa"
DB_PASSWORD = os.environ.get("SA_PASSWORD")
FLASK_PORT = int(os.environ.get("FLASK_PORT", 5000))

CONN_STR = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    f"SERVER={DB_SERVER};DATABASE={DB_NAME};"
    f"UID={DB_USER};PWD={DB_PASSWORD};"
    "TrustServerCertificate=yes;Encrypt=yes;"
)


@contextmanager
def db():
    """DB 컨텍스트 매니저 — 자동 commit/rollback"""
    conn = pyodbc.connect(CONN_STR, autocommit=False)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ===================================================
# Health
# ===================================================
@app.route("/health")
def health():
    try:
        with db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
            cur.fetchone()
        return jsonify({"status": "ok", "db": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "error", "db": str(e)}), 500


# ===================================================
# Users
# ===================================================
@app.route("/api/users", methods=["GET"])
def list_users():
    with db() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT UserId, Name, Email, Phone, UserType FROM Users ORDER BY UserId"
        )
        rows = cur.fetchall()
    return jsonify(
        [
            {"id": r[0], "name": r[1], "email": r[2], "phone": r[3], "type": r[4]}
            for r in rows
        ]
    )


# ===================================================
# Cars — list with filters
# ===================================================
@app.route("/api/cars", methods=["GET"])
def list_cars():
    brand = request.args.get("brand")
    max_price = request.args.get("max_price", type=int)

    sql = """
        SELECT c.CarId, u.Name, c.Brand, c.Model, c.Year, c.Price,
               c.Mileage, c.FuelType, c.Description, c.Status, c.CreatedAt
          FROM Cars c
          JOIN Users u ON c.SellerId = u.UserId
         WHERE c.Status = 'available'
    """
    params = []
    if brand:
        sql += " AND c.Brand = ?"
        params.append(brand)
    if max_price:
        sql += " AND c.Price <= ?"
        params.append(max_price)
    sql += " ORDER BY c.CreatedAt DESC"

    with db() as conn:
        cur = conn.cursor()
        cur.execute(sql, params)
        rows = cur.fetchall()

    return jsonify(
        [
            {
                "id": r[0],
                "seller": r[1],
                "brand": r[2],
                "model": r[3],
                "year": r[4],
                "price": int(r[5]),
                "mileage": r[6],
                "fuel": r[7],
                "desc": r[8],
                "status": r[9],
                "created_at": r[10].isoformat() if r[10] else None,
            }
            for r in rows
        ]
    )


# ===================================================
# Cars — create
# ===================================================
@app.route("/api/cars", methods=["POST"])
def create_car():
    data = request.get_json(silent=True) or {}
    required = ["seller_id", "brand", "model", "year", "price", "mileage"]
    missing = [k for k in required if k not in data]
    if missing:
        return jsonify({"error": f"missing fields: {missing}"}), 400

    with db() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO Cars (SellerId, Brand, Model, Year, Price, Mileage, FuelType, Description)
            OUTPUT INSERTED.CarId
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            data["seller_id"],
            data["brand"],
            data["model"],
            int(data["year"]),
            int(data["price"]),
            int(data["mileage"]),
            data.get("fuel", ""),
            data.get("desc", ""),
        )
        new_id = cur.fetchone()[0]
    return jsonify({"car_id": new_id}), 201


# ===================================================
# Inquiries — create
# ===================================================
@app.route("/api/inquiries", methods=["POST"])
def create_inquiry():
    data = request.get_json(silent=True) or {}
    for k in ("car_id", "buyer_id", "message"):
        if k not in data:
            return jsonify({"error": f"missing {k}"}), 400

    with db() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO Inquiries (CarId, BuyerId, Message)
            OUTPUT INSERTED.InquiryId
            VALUES (?, ?, ?)
            """,
            int(data["car_id"]),
            int(data["buyer_id"]),
            data["message"],
        )
        new_id = cur.fetchone()[0]
    return jsonify({"inquiry_id": new_id}), 201


# ===================================================
# UI
# ===================================================
@app.route("/")
def index():
    return render_template("index.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=FLASK_PORT, debug=False)
