"""
Add a sample Ziyara trip (حملة زيارة) to Firestore for testing.

Requirements:
    pip install firebase-admin

Usage:
    python3 tools/add_sample_trip.py --key serviceAccountKey.json

This writes one document to the "trips" collection with multiple named
contacts, so you can see the new حملات الزيارة page working immediately.

Edit the TRIP dict below to add your real trip details, then re-run.
"""

import argparse
from datetime import datetime, timedelta
import firebase_admin
from firebase_admin import credentials, firestore

# ─── Edit this block with your real trip ────────────────────────────────────
TRIP = {
    "title": "حملة زيارة الأربعين",
    "destination": "كربلاء المقدسة",
    "departureFrom": "أمام مسجد وحسينية أهل البيت - المنصور",
    "imageUrl": "",  # optional: paste an image URL
    "price": "50000",
    "seats": "12",
    "description": "حملة مباركة لزيارة الأربعين، تشمل النقل والإقامة.",
    # Departure 7 days from now, return 3 days after that
    "departureDate": datetime.now() + timedelta(days=7),
    "returnDate": datetime.now() + timedelta(days=10),
    "contacts": [
        {"name": "أبو علي",  "label": "رجال ١", "phone": "9647701234567"},
        {"name": "أبو حسن",  "label": "رجال ٢", "phone": "9647709876543"},
        {"name": "أم زينب",  "label": "نساء",   "phone": "9647701111111"},
    ],
}
# ─────────────────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--key", required=True,
                        help="Path to Firebase service account JSON key")
    args = parser.parse_args()

    cred = credentials.Certificate(args.key)
    firebase_admin.initialize_app(cred)
    db = firestore.client()

    doc_ref = db.collection("trips").add(TRIP)
    print(f"Added trip: {TRIP['title']}")
    print(f"Document ID: {doc_ref[1].id}")
    print("Open the app → الحملات tab → القادمة to see it.")


if __name__ == "__main__":
    main()
