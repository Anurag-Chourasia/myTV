#!/usr/bin/env python3
"""
Collect MyTV live & scenario network logs and generate AppStubData mock fixtures
for Positive, Empty, and Negative scenarios across IPTV-org API endpoints
(Channels, Streams, Logos, Categories, Countries, Playlists).
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
MYTV_LOGS_DIR = ROOT_DIR / "MyTV" / "Logs"
DEV_STUBS_DIR = ROOT_DIR / "DevOps" / "AppStubData" / "Sources" / "AppStubData" / "Resources"
LOCAL_MOCK_DIR = ROOT_DIR / "MyTV" / "TestSupport" / "MockData"

MYTV_LOGS_DIR.mkdir(parents=True, exist_ok=True)
DEV_STUBS_DIR.mkdir(parents=True, exist_ok=True)
LOCAL_MOCK_DIR.mkdir(parents=True, exist_ok=True)

USER_AGENT = "myTV/1.0 (iOS; Darwin)"

log_entries = []

def record_http_log(method, url, status, duration_ms, request_headers, response_headers, body_str, is_error=False, error_msg=None):
    req_id = str(uuid.uuid4()).upper()
    req_header_str = "\n".join(f"  {k}: {v}" for k, v in request_headers.items())
    resp_header_str = "\n".join(f"  {k}: {v}" for k, v in response_headers.items()) if response_headers else "  <none>"

    log_part = f"""========== HTTP REQUEST ==========
Request ID: {req_id}
Method: {method}
URL: {url}
Headers:
{req_header_str}
Request Body:
<no request body>
=================================

"""
    if is_error:
        log_part += f"""========== HTTP ERROR ============
Request ID: {req_id}
Method: {method}
URL: {url}
Duration: {duration_ms:.2f} ms
Error: {error_msg or f'HTTP {status}'}
Response Body:
{body_str}
==================================

"""
    else:
        log_part += f"""========== HTTP RESPONSE =========
Request ID: {req_id}
Method: {method}
URL: {url}
Final URL: {url}
Status: {status}
Duration: {duration_ms:.2f} ms
Headers:
{resp_header_str}
Response Body:
{body_str}
==================================

"""
    log_entries.append(log_part)
    return req_id

def fetch_live_or_fallback(name, url, fallback_data, status_expected=200):
    print(f"Fetching live: {name} ({url})...")
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json"})
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            duration_ms = (time.time() - t0) * 1000
            raw = resp.read()
            text = raw.decode("utf-8", errors="replace")
            resp_headers = dict(resp.headers)
            record_http_log("GET", url, resp.status, duration_ms, {"User-Agent": USER_AGENT}, resp_headers, text[:2000] + ("..." if len(text) > 2000 else ""))
            try:
                parsed = json.loads(text)
                # If large catalog, take a curated sample of top items
                if isinstance(parsed, list) and len(parsed) > 10:
                    sample_ids = {"bbc-news.uk", "france24.fr", "dw-english.de", "redbull-tv.at", "nasa-tv.us", "dd-india.in"}
                    sampled = [item for item in parsed if item.get("id") in sample_ids or item.get("channel") in sample_ids]
                    if len(sampled) >= 3:
                        return sampled
                    return parsed[:6]
                return parsed
            except Exception:
                return fallback_data
    except urllib.error.HTTPError as e:
        duration_ms = (time.time() - t0) * 1000
        raw = e.read()
        text = raw.decode("utf-8", errors="replace")
        resp_headers = dict(e.headers)
        record_http_log("GET", url, e.code, duration_ms, {"User-Agent": USER_AGENT}, resp_headers, text, is_error=True, error_msg=f"HTTPError {e.code} ({e.reason})")
        try:
            return json.loads(text)
        except Exception:
            return fallback_data
    except Exception as e:
        duration_ms = (time.time() - t0) * 1000
        record_http_log("GET", url, 0, duration_ms, {"User-Agent": USER_AGENT}, {}, str(fallback_data), is_error=True, error_msg=f"Transport error: {str(e)}")
        return fallback_data

# ==========================================
# 1. POSITIVE SCENARIOS (IPTV live or curated)
# ==========================================

fallback_channels = [
    {
        "id": "bbc-news.uk",
        "name": "BBC News",
        "alt_names": ["BBC News 24"],
        "network": "BBC",
        "owners": ["British Broadcasting Corporation"],
        "country": "GB",
        "categories": ["news"],
        "is_nsfw": False,
        "launched": "1997-11-09",
        "closed": None,
        "replaced_by": None,
        "website": "https://www.bbc.co.uk/news"
    },
    {
        "id": "france24.fr",
        "name": "France 24 English",
        "alt_names": ["F24 EN"],
        "network": "France Medias Monde",
        "owners": ["French State"],
        "country": "FR",
        "categories": ["news", "international"],
        "is_nsfw": False,
        "launched": "2006-12-06",
        "closed": None,
        "replaced_by": None,
        "website": "https://www.france24.com"
    },
    {
        "id": "dw-english.de",
        "name": "DW English",
        "alt_names": ["Deutsche Welle"],
        "network": "DW",
        "owners": ["German Public Broadcaster"],
        "country": "DE",
        "categories": ["news", "documentary"],
        "is_nsfw": False,
        "launched": "1992-04-01",
        "closed": None,
        "replaced_by": None,
        "website": "https://www.dw.com"
    },
    {
        "id": "redbull-tv.at",
        "name": "Red Bull TV",
        "alt_names": ["RBTV"],
        "network": "Red Bull Media House",
        "owners": ["Red Bull GmbH"],
        "country": "AT",
        "categories": ["sports", "entertainment"],
        "is_nsfw": False,
        "launched": "2010-04-01",
        "closed": None,
        "replaced_by": None,
        "website": "https://www.redbull.com/tv"
    },
    {
        "id": "nasa-tv.us",
        "name": "NASA TV Public",
        "alt_names": ["NASA Television"],
        "network": "NASA",
        "owners": ["United States Government"],
        "country": "US",
        "categories": ["science", "education"],
        "is_nsfw": False,
        "launched": "1980-07-20",
        "closed": None,
        "replaced_by": None,
        "website": "https://www.nasa.gov/multimedia/nasatv"
    },
    {
        "id": "dd-india.in",
        "name": "DD India",
        "alt_names": ["Doordarshan India"],
        "network": "Doordarshan",
        "owners": ["Prasar Bharati"],
        "country": "IN",
        "categories": ["news", "culture"],
        "is_nsfw": False,
        "launched": "1995-03-14",
        "closed": None,
        "replaced_by": None,
        "website": "https://prasarbharati.gov.in"
    }
]

fallback_streams = [
    {
        "channel": "bbc-news.uk",
        "feed": "uk-hls",
        "title": "BBC News 1080p",
        "url": "https://fixture.invalid/streams/bbc-1080p.m3u8",
        "referrer": "https://bbc.co.uk",
        "user_agent": "MyTV/1.0",
        "quality": "1080p"
    },
    {
        "channel": "france24.fr",
        "feed": "en-live",
        "title": "France 24 HD",
        "url": "https://fixture.invalid/streams/france24-hd.m3u8",
        "referrer": "https://france24.com",
        "user_agent": None,
        "quality": "1080p"
    },
    {
        "channel": "dw-english.de",
        "feed": "en-worldwide",
        "title": "DW English Live 720p",
        "url": "https://fixture.invalid/streams/dw-live.m3u8",
        "referrer": None,
        "user_agent": None,
        "quality": "720p"
    },
    {
        "channel": "redbull-tv.at",
        "feed": "global",
        "title": "Red Bull TV Live",
        "url": "https://fixture.invalid/streams/redbull-live.m3u8",
        "referrer": None,
        "user_agent": None,
        "quality": "1080p"
    },
    {
        "channel": "nasa-tv.us",
        "feed": "public-hd",
        "title": "NASA TV HD Stream",
        "url": "https://fixture.invalid/streams/nasa-hd.m3u8",
        "referrer": None,
        "user_agent": None,
        "quality": "1080p"
    },
    {
        "channel": "dd-india.in",
        "feed": "national",
        "title": "DD India Standard",
        "url": "https://fixture.invalid/streams/dd-india.m3u8",
        "referrer": None,
        "user_agent": None,
        "quality": "720p"
    }
]

fallback_logos = [
    {
        "channel": "bbc-news.uk",
        "feed": None,
        "tags": ["primary", "dark"],
        "width": 512,
        "height": 512,
        "format": "PNG",
        "url": "https://fixture.invalid/logos/bbc-news.png"
    },
    {
        "channel": "france24.fr",
        "feed": None,
        "tags": ["primary", "light"],
        "width": 512,
        "height": 512,
        "format": "PNG",
        "url": "https://fixture.invalid/logos/france24.png"
    },
    {
        "channel": "dw-english.de",
        "feed": None,
        "tags": ["primary"],
        "width": 512,
        "height": 512,
        "format": "PNG",
        "url": "https://fixture.invalid/logos/dw.png"
    },
    {
        "channel": "redbull-tv.at",
        "feed": None,
        "tags": ["primary"],
        "width": 512,
        "height": 512,
        "format": "PNG",
        "url": "https://fixture.invalid/logos/redbull.png"
    },
    {
        "channel": "nasa-tv.us",
        "feed": None,
        "tags": ["primary"],
        "width": 512,
        "height": 512,
        "format": "PNG",
        "url": "https://fixture.invalid/logos/nasa.png"
    },
    {
        "channel": "dd-india.in",
        "feed": None,
        "tags": ["primary"],
        "width": 512,
        "height": 512,
        "format": "PNG",
        "url": "https://fixture.invalid/logos/dd-india.png"
    }
]

fallback_categories = [
    {"id": "news", "name": "News"},
    {"id": "sports", "name": "Sports"},
    {"id": "science", "name": "Science"},
    {"id": "entertainment", "name": "Entertainment"},
    {"id": "documentary", "name": "Documentary"}
]

channels_pos = fetch_live_or_fallback("IPTV Channels", "https://iptv-org.github.io/api/channels.json", fallback_channels)
streams_pos = fetch_live_or_fallback("IPTV Streams", "https://iptv-org.github.io/api/streams.json", fallback_streams)
logos_pos = fetch_live_or_fallback("IPTV Logos", "https://iptv-org.github.io/api/logos.json", fallback_logos)
categories_pos = fetch_live_or_fallback("IPTV Categories", "https://iptv-org.github.io/api/categories.json", fallback_categories)

# ==========================================
# 2. EMPTY SCENARIOS
# ==========================================

channels_empty = []
streams_empty = []
logos_empty = []
categories_empty = []

for name, url, payload in [
    ("Channels (Empty)", "https://iptv-org.github.io/api/channels.json?country=XX", channels_empty),
    ("Streams (Empty)", "https://iptv-org.github.io/api/streams.json?channel=unknown-id", streams_empty),
    ("Logos (Empty)", "https://iptv-org.github.io/api/logos.json?channel=unknown-id", logos_empty),
    ("Categories (Empty)", "https://iptv-org.github.io/api/categories.json?id=none", categories_empty),
]:
    record_http_log("GET", url, 200, 18.0, {"User-Agent": USER_AGENT}, {"Content-Type": "application/json"}, json.dumps(payload, indent=2))

# ==========================================
# 3. NEGATIVE SCENARIOS
# ==========================================

channels_negative = [
    {"unexpected_field": 12345, "broken_id": None},
    {"id": 99999, "name": None, "country": False}
]

streams_negative = [
    {"broken_channel": None, "missing_url": True},
    {"url": "not-a-valid-url-format", "quality": 1080}
]

logos_negative = [
    {"broken_logo": True, "width": "invalid-dimension", "height": None}
]

categories_negative = [
    {"bad_category_id": 0, "name": False}
]

error_response = {
    "status": "error",
    "code": 500,
    "error": "InternalServerError",
    "message": "Directory endpoint temporarily unavailable. Please retry later.",
    "timestamp": "2026-10-26T23:55:00Z"
}

offline_error = {
    "domain": "NSURLErrorDomain",
    "code": -1009,
    "description": "The Internet connection appears to be offline."
}

for name, url, code, payload in [
    ("Channels (Negative Malformed)", "https://iptv-org.github.io/api/channels.json?corrupt=1", 200, channels_negative),
    ("Streams (Negative Malformed)", "https://iptv-org.github.io/api/streams.json?corrupt=1", 200, streams_negative),
    ("Logos (Negative Malformed)", "https://iptv-org.github.io/api/logos.json?corrupt=1", 200, logos_negative),
    ("Categories (Negative Malformed)", "https://iptv-org.github.io/api/categories.json?corrupt=1", 200, categories_negative),
    ("Directory Server Error 500", "https://iptv-org.github.io/api/error-endpoint", 500, error_response),
]:
    record_http_log("GET", url, code, 40.0, {"User-Agent": USER_AGENT}, {"Content-Type": "application/json"}, json.dumps(payload, indent=2), is_error=(code != 200), error_msg=(f"HTTP {code}" if code != 200 else None))

record_http_log("GET", "https://iptv-org.github.io/api/channels.json", 0, 8.0, {"User-Agent": USER_AGENT}, {}, json.dumps(offline_error, indent=2), is_error=True, error_msg="Transport error: URLError(-1009, 'offline')")

# ==========================================
# 4. SAVE APPSTUBDATA & MOCK FIXTURES
# ==========================================

fixtures_map = {
    # Positive
    "mytv-channels-positive": channels_pos,
    "mytv-streams-positive": streams_pos,
    "mytv-logos-positive": logos_pos,
    "mytv-categories-positive": categories_pos,

    # Empty
    "mytv-channels-empty": channels_empty,
    "mytv-streams-empty": streams_empty,
    "mytv-logos-empty": logos_empty,
    "mytv-categories-empty": categories_empty,

    # Negative
    "mytv-channels-negative": channels_negative,
    "mytv-streams-negative": streams_negative,
    "mytv-logos-negative": logos_negative,
    "mytv-categories-negative": categories_negative,
    "mytv-error-response": error_response,
    "mytv-offline-error": offline_error,
}

for name, data in fixtures_map.items():
    json_bytes = json.dumps(data, indent=2).encode("utf-8")
    for target_dir in [DEV_STUBS_DIR, LOCAL_MOCK_DIR]:
        target_path = target_dir / f"{name}.json"
        target_path.write_bytes(json_bytes)
        print(f"Saved fixture: {target_path}")

# Write log file
log_file = MYTV_LOGS_DIR / "network_scenarios.log"
log_file.write_text("".join(log_entries), encoding="utf-8")
print(f"\nSuccessfully wrote {len(log_entries)} HTTP log sessions to {log_file}")
