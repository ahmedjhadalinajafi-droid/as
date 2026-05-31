"""
Upload prayer times for a full year to Firebase Firestore.

Requirements:
    pip install firebase-admin requests

Usage:
    python3 tools/upload_prayer_times.py --year 2026 --key path/to/serviceAccountKey.json

How to get serviceAccountKey.json:
    Firebase Console → Project Settings → Service Accounts → Generate new private key

After running, each day is stored in Firestore as:
    prayer_times / YYYY-MM-DD
    Fields: fajr, sunrise, dhuhr, sunset, maghrib, midnight  (all "HH:MM" strings)

Admin can then open any document in Firebase Console and edit a field to override it.
"""

import argparse
import time
import requests
import firebase_admin
from firebase_admin import credentials, firestore

# Baghdad coordinates — Shia Ithna-Ashari method (13)
LAT = 33.3152
LON = 44.3661
METHOD = 13

PRAYER_MAP = {
    "Fajr":     "fajr",
    "Sunrise":  "sunrise",
    "Dhuhr":    "dhuhr",
    "Sunset":   "sunset",
    "Maghrib":  "maghrib",
    "Midnight": "midnight",
}


def strip_tz(t: str) -> str:
    return t.split(" ")[0]


def fetch_month(year: int, month: int) -> dict:
    url = (
        f"https://api.aladhan.com/v1/calendar/{year}/{month}"
        f"?latitude={LAT}&longitude={LON}&method={METHOD}"
    )
    r = requests.get(url, timeout=20)
    r.raise_for_status()
    return r.json()["data"]


def upload_year(year: int, db):
    collection = db.collection("prayer_times")
    total = 0

    for month in range(1, 13):
        print(f"  Fetching {year}-{month:02d} ...", end=" ", flush=True)
        try:
            days = fetch_month(year, month)
        except Exception as e:
            print(f"FAILED: {e}")
            continue

        batch = db.batch()
        count = 0
        for day in days:
            greg    = day["date"]["gregorian"]["date"]   # "DD-MM-YYYY"
            p       = greg.split("-")
            doc_id  = f"{p[2]}-{p[1]}-{p[0]}"           # "YYYY-MM-DD"
            timings = day["timings"]

            data = {
                key: strip_tz(timings.get(api_key, ""))
                for api_key, key in PRAYER_MAP.items()
            }
            batch.set(collection.document(doc_id), data)
            count += 1

        batch.commit()
        total += count
        print(f"uploaded {count} days")
        time.sleep(0.5)   # be polite to the API

    print(f"\nDone — {total} documents written to Firestore.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--year", type=int, default=2026)
    parser.add_argument("--key",  required=True,
                        help="Path to Firebase service account JSON key")
    args = parser.parse_args()

    cred = credentials.Certificate(args.key)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    print(f"Uploading prayer times for {args.year} to Firestore...")
    upload_year(args.year, db)


if __name__ == "__main__":
    main()
