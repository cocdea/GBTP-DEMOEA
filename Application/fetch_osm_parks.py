"""Fetch real park coordinates from OpenStreetMap (paper-scale, 400+ points)."""
import csv
import json
import math
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DATA_DIR = ROOT / "data"

# Paper: Shenzhen parks. OSM bbox covers main urban area + nearby.
CITY_QUERIES = {
    "shenzhen": (
        "("
        '  node["leisure"~"park|garden|nature_reserve"](22.44,113.74,22.88,114.68);'
        '  way["leisure"~"park|garden|nature_reserve"](22.44,113.74,22.88,114.68);'
        '  node["landuse"="recreation_ground"](22.44,113.74,22.88,114.68);'
        '  way["landuse"="recreation_ground"](22.44,113.74,22.88,114.68);'
        ");"
        "out center 800;"
    ),
    "chongqing": (
        "("
        '  node(area.cq)["leisure"~"park|garden|nature_reserve"];'
        '  way(area.cq)["leisure"~"park|garden|nature_reserve"];'
        ");"
        "out center 800;"
    ),
    "chengdu": (
        "("
        '  node(area.cd)["leisure"~"park|garden|nature_reserve"];'
        '  way(area.cd)["leisure"~"park|garden|nature_reserve"];'
        ");"
        "out center 800;"
    ),
    "wuhan": (
        "("
        '  node(area.wh)["leisure"~"park|garden|nature_reserve"];'
        '  way(area.wh)["leisure"~"park|garden|nature_reserve"];'
        ");"
        "out center 800;"
    ),
    "guangzhou": (
        "("
        '  node["leisure"~"park|garden|nature_reserve"](22.8,113.0,23.6,113.6);'
        '  way["leisure"~"park|garden|nature_reserve"](22.8,113.0,23.6,113.6);'
        ");"
        "out center 800;"
    ),
}

CITY_PREFIX = {
    "chongqing": 'area["name:en"="Chongqing"]["admin_level"="4"]->.cq;',
    "chengdu": 'area["name:en"="Chengdu"]["admin_level"="4"]->.cd;',
    "wuhan": 'area["name:en"="Wuhan"]["admin_level"="4"]->.wh;',
}

OVERPASS_URLS = [
    "https://overpass.kumi.systems/api/interpreter",
    "https://overpass-api.de/api/interpreter",
]

SKIP_NAME_KEYWORDS = ("厕所", "toilet", "停车场", "parking", "wc", "restroom")


def fetch_overpass(query: str) -> dict:
    payload = f"[out:json][timeout:120];{query}"
    data = payload.encode("utf-8")
    last_err = None
    for url in OVERPASS_URLS:
        req = urllib.request.Request(
            url,
            data=data,
            method="POST",
            headers={
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                "User-Agent": "CT-DEMOEA-park-fetch/1.0 (research)",
                "Accept": "application/json",
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            last_err = exc
    raise RuntimeError(f"All Overpass endpoints failed: {last_err}")


def build_query(city: str) -> str:
    body = CITY_QUERIES[city]
    prefix = CITY_PREFIX.get(city, "")
    return prefix + body


def element_name(tags: dict, el_id) -> str:
    for key in ("name:zh", "name", "name:en", "alt_name"):
        if key in tags and tags[key]:
            return str(tags[key]).replace(",", " ").strip()
    return f"Park_{el_id}"


def should_skip(name: str) -> bool:
    low = name.lower()
    return any(k in name or k in low for k in SKIP_NAME_KEYWORDS)


def elements_to_rows(payload: dict, city: str):
    rows = []
    for el in payload.get("elements", []):
        lat = el.get("lat")
        lon = el.get("lon")
        if lat is None or lon is None:
            center = el.get("center") or {}
            lat = center.get("lat")
            lon = center.get("lon")
        if lat is None or lon is None:
            continue
        tags = el.get("tags", {})
        name = element_name(tags, el["id"])
        if should_skip(name):
            continue
        rows.append(
            {
                "id": el["id"],
                "name": name,
                "lon": round(float(lon), 6),
                "lat": round(float(lat), 6),
                "city": city,
            }
        )
    return dedupe_rows(rows)


def dedupe_rows(rows, min_dist_m=80.0):
    """Remove near-duplicate points (~same location)."""
    kept = []
    for row in rows:
        dup = False
        for k in kept:
            if haversine_m(row["lat"], row["lon"], k["lat"], k["lon"]) < min_dist_m:
                dup = True
                break
        if not dup:
            kept.append(row)
    return kept


def haversine_m(lat1, lon1, lat2, lon2):
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlmb = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def save_csv(rows, out_path: Path):
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with out_path.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["id", "name", "lon", "lat", "city"])
        writer.writeheader()
        writer.writerows(rows)


def main():
    city = sys.argv[1] if len(sys.argv) > 1 else "shenzhen"
    min_target = int(sys.argv[2]) if len(sys.argv) > 2 else 441

    if city not in CITY_QUERIES:
        print(f"Unknown city: {city}. Choose from: {', '.join(CITY_QUERIES)}")
        sys.exit(1)

    print(f"Fetching parks for {city} from OpenStreetMap (target >= {min_target}) ...")
    payload = fetch_overpass(build_query(city))
    rows = elements_to_rows(payload, city)
    print(f"Raw unique parks: {len(rows)}")

    if len(rows) < min_target:
        print(f"Warning: got {len(rows)} parks (< {min_target}).")
        print("Try: python fetch_osm_parks.py guangzhou 441  and merge, or lower paperPreset counts.")

    out_csv = DATA_DIR / f"{city}_parks_real.csv"
    save_csv(rows, out_csv)
    print(f"Saved {len(rows)} parks -> {out_csv}")

    if city == "shenzhen" or len(rows) >= min_target:
        save_csv(rows, DATA_DIR / "parks_real.csv")
        print(f"Also saved -> {DATA_DIR / 'parks_real.csv'}")


if __name__ == "__main__":
    main()
