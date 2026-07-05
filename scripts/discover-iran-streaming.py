#!/usr/bin/env python3
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
SERVICE_DIR = ROOT_DIR / "services" / "iran-streaming"
DATABASE_FILE = SERVICE_DIR / "database" / "domains.txt"
USER_AGENT = "iran-streaming-route-list/1.0"

COMMON_HOSTS = (
    "account", "api", "app", "asset", "assets", "auth", "cdn", "cdn1", "cdn2", "cdn3",
    "dl", "download", "edge", "event", "gateway", "img", "image", "images", "live",
    "log", "m", "media", "mobile", "payment", "play", "player", "s", "search",
    "static", "static1", "static2", "static3", "stream", "tv", "upload", "video", "vod", "www",
)

URL_RE = re.compile(r"""(?i)\bhttps?://[^\s\"'<>\\]+""")


def fetch_text(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as response:
        return response.read().decode("utf-8", "replace")


def load_root_domains():
    roots = set()
    if not DATABASE_FILE.exists():
        return roots
    for line in DATABASE_FILE.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.split("#", 1)[0].strip().lower()
        if not line:
            continue
        line = re.sub(r"^https?://", "", line).split("/", 1)[0].split(":", 1)[0].strip(".")
        if line.startswith("*."):
            line = line[2:]
        if re.fullmatch(r"[a-z0-9.-]+\.[a-z]{2,}", line):
            roots.add(line)
    return roots


ROOT_DOMAINS = tuple(sorted(load_root_domains()))
HOST_RE = re.compile(r"(?i)\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+(?:" + "|".join(re.escape(root) for root in ROOT_DOMAINS) + r")\b") if ROOT_DOMAINS else re.compile(r"a^")
SEED_URLS = tuple(f"https://{root}/" for root in ROOT_DOMAINS) + tuple(f"https://www.{root}/" for root in ROOT_DOMAINS)


def normalize_host(value):
    value = value.strip().lower()
    value = re.sub(r"^https?://", "", value)
    value = value.split("/", 1)[0].split(":", 1)[0].strip(".")
    if value.startswith("*."):
        value = value[2:]
    if not value or "*" in value:
        return None
    if any(value == root or value.endswith("." + root) for root in ROOT_DOMAINS):
        return value
    return None


def add_hosts_from_text(hosts, text):
    for match in HOST_RE.findall(text or ""):
        host = normalize_host(match)
        if host:
            hosts.add(host)


def add_urls_from_text(urls, hosts, text):
    for match in URL_RE.findall(text or ""):
        parsed = urllib.parse.urlsplit(match.rstrip(".,);]"))
        host = normalize_host(parsed.netloc)
        if host:
            hosts.add(host)
            urls.add(urllib.parse.urlunsplit((parsed.scheme.lower(), host, parsed.path, parsed.query, "")))


def load_seed_hosts(hosts):
    for root in ROOT_DOMAINS:
        hosts.add(root)
        for prefix in COMMON_HOSTS:
            hosts.add(f"{prefix}.{root}")


def load_crtsh(hosts):
    for root in ROOT_DOMAINS:
        url = f"https://crt.sh/?q=%25.{urllib.parse.quote(root)}&output=json"
        try:
            data = json.loads(fetch_text(url))
        except Exception as exc:
            print(f"warning: crt.sh failed for {root}: {exc}", file=sys.stderr)
            continue
        for item in data:
            add_hosts_from_text(hosts, item.get("name_value", ""))
            add_hosts_from_text(hosts, item.get("common_name", ""))


def load_urlscan(hosts, urls):
    for root in ROOT_DOMAINS:
        api_url = f"https://urlscan.io/api/v1/search/?q=domain:{urllib.parse.quote(root)}&size=100"
        try:
            data = json.loads(fetch_text(api_url))
        except Exception as exc:
            print(f"warning: urlscan failed for {root}: {exc}", file=sys.stderr)
            continue
        for result in data.get("results", []):
            for section_name in ("task", "page"):
                section = result.get(section_name) or {}
                add_urls_from_text(urls, hosts, section.get("url", ""))
                add_hosts_from_text(hosts, section.get("domain", ""))


def crawl_seed_pages(hosts, urls):
    for url in SEED_URLS:
        try:
            text = fetch_text(url)
        except Exception as exc:
            print(f"warning: page fetch failed for {url}: {exc}", file=sys.stderr)
            continue
        add_hosts_from_text(hosts, text)
        add_urls_from_text(urls, hosts, text)


def write_lines(path, values):
    path.write_text("".join(f"{value}\n" for value in sorted(values)), encoding="utf-8")


def main():
    hosts = set()
    urls = set()

    load_seed_hosts(hosts)
    load_crtsh(hosts)
    load_urlscan(hosts, urls)
    crawl_seed_pages(hosts, urls)

    host_urls = {f"https://{host}/" for host in hosts}

    write_lines(ROOT_DIR / "iran-streaming-domains.txt", hosts)
    write_lines(ROOT_DIR / "iran-streaming-urls.txt", urls | host_urls)

    print(f"domains: {len(hosts)}")
    print(f"urls: {len(urls | host_urls)}")


if __name__ == "__main__":
    main()
