#!/usr/bin/env python3
"""
Verify RevenueCat `pro` entitlement for a subscriber after a test purchase.

IMPORTANT: RevenueCat REST API requires the SECRET API key (sk_...), not the
public SDK key (goog_...) in REVENUECAT_KEY. Add to app/.env:

  REVENUECAT_SECRET_KEY=sk_your_secret_key

Get it from: RevenueCat Dashboard → Project → API keys → Secret API keys

The app_user_id must match what the app sends to RevenueCat via Purchases.logIn().
That is your Firebase Auth UID (same as userId in AppState).

Usage:
  python scripts/verify_revenuecat_entitlement.py --user-id abc123firebaseUid
  python scripts/verify_revenuecat_entitlement.py --user-id abc123 --watch 30
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENV_FILE = ROOT / "app" / ".env"
API_BASE = "https://api.revenuecat.com/v1"


def load_env(path: Path) -> dict[str, str]:
    env: dict[str, str] = {}
    if not path.exists():
        return env
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        env[key.strip()] = val.strip().strip('"').strip("'")
    return env


def resolve_secret_key(env: dict[str, str]) -> str:
    for key in ("REVENUECAT_SECRET_KEY", "REVENUECAT_API_SECRET", "REVENUECAT_SK"):
        if env.get(key, "").startswith("sk_"):
            return env[key]
    public = env.get("REVENUECAT_KEY", "")
    if public.startswith("sk_"):
        return public
    if public.startswith("goog_") or public.startswith("appl_"):
        print(
            "ERROR: REVENUECAT_KEY is the public SDK key (goog_/appl_).\n"
            "REST API needs a SECRET key (sk_...).\n"
            "Add REVENUECAT_SECRET_KEY=sk_... to app/.env\n"
            "RevenueCat Dashboard → API keys → Secret API keys",
            file=sys.stderr,
        )
        sys.exit(2)
    print("ERROR: No REVENUECAT_SECRET_KEY (sk_...) found in app/.env", file=sys.stderr)
    sys.exit(2)


def fetch_subscriber(secret_key: str, app_user_id: str) -> dict:
    url = f"{API_BASE}/subscribers/{app_user_id}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {secret_key}",
            "Content-Type": "application/json",
        },
        method="GET",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors="replace")
        print(f"HTTP {e.code}: {body}", file=sys.stderr)
        if e.code == 404:
            print(
                "\nSubscriber not found. Common causes:\n"
                "  - Wrong --user-id (must be Firebase UID used at login)\n"
                "  - Purchase not completed yet\n"
                "  - App has not called Purchases.logIn() for this user",
                file=sys.stderr,
            )
        sys.exit(1)


def parse_expires(expires: str | None) -> datetime | None:
    if not expires:
        return None
    # RevenueCat uses ISO8601 e.g. 2026-07-11T01:00:00Z
    expires = expires.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(expires)
    except ValueError:
        return None


def check_pro_entitlement(data: dict) -> tuple[bool, dict | None]:
    subscriber = data.get("subscriber") or data
    entitlements = subscriber.get("entitlements") or {}
    pro = entitlements.get("pro")
    if not pro:
        return False, None

    expires = parse_expires(pro.get("expires_date"))
    now = datetime.now(timezone.utc)
    if expires is None:
        # Lifetime / non-expiring
        active = True
    else:
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        active = expires > now

    return active, pro


def print_report(app_user_id: str, data: dict, active: bool, pro: dict | None) -> None:
    subscriber = data.get("subscriber") or data
    print(f"\nSubscriber: {app_user_id}")
    print(f"First seen: {subscriber.get('first_seen', 'n/a')}")
    print(f"Management URL: {subscriber.get('management_url', 'n/a')}")

    subs = subscriber.get("subscriptions") or {}
    if subs:
        print("\nSubscriptions:")
        for product_id, sub in subs.items():
            print(f"  - {product_id}: {sub.get('store', '?')} | expires {sub.get('expires_date', 'n/a')}")

    if pro:
        print("\nEntitlement `pro`:")
        print(f"  product_identifier: {pro.get('product_identifier')}")
        print(f"  expires_date:       {pro.get('expires_date')}")
        print(f"  purchase_date:      {pro.get('purchase_date')}")
        print(f"  store:              {pro.get('store')}")

    print()
    if active:
        print("✅ pro entitlement is ACTIVE")
    else:
        print("❌ pro entitlement is NOT active")
    print()


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify RevenueCat pro entitlement")
    parser.add_argument("--user-id", required=True, help="Firebase UID (RevenueCat app_user_id)")
    parser.add_argument(
        "--watch",
        type=int,
        default=0,
        metavar="SECONDS",
        help="Poll every N seconds until pro is active (0 = single check)",
    )
    parser.add_argument("--env", default=str(ENV_FILE), help="Path to .env file")
    args = parser.parse_args()

    env = load_env(Path(args.env))
    secret = resolve_secret_key(env)
    app_user_id = args.user_id.strip()

    def once() -> bool:
        data = fetch_subscriber(secret, app_user_id)
        active, pro = check_pro_entitlement(data)
        print_report(app_user_id, data, active, pro)
        return active

    if args.watch <= 0:
        return 0 if once() else 1

    print(f"Polling every {args.watch}s for active pro entitlement (Ctrl+C to stop)...")
    while True:
        try:
            if once():
                return 0
        except KeyboardInterrupt:
            print("\nStopped.")
            return 1
        time.sleep(args.watch)


if __name__ == "__main__":
    sys.exit(main())
