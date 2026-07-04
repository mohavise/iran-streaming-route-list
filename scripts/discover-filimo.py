#!/usr/bin/env python3
import ipaddress
import json
import re
import socket
import sys
import urllib.parse
import urllib.request
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
USER_AGENT = "filimo-route-list/1.0"
socket.setdefaulttimeout(8)
ROOT_DOMAINS = ("filimo.com",)
SEED_URLS = (
    "https://filimo.com/",
    "https://www.filimo.com/",
)
COMMON_HOSTS = (
    "account",
    "api",
    "asset",
    "assets",
    "auth",
    "cdn",
    "download",
    "event",
    "gateway",
    "img",
    "image",
    "images",
    "live",
    "log",
    "media",
    "payment",
    "player",
    "search",
    "static",
    "static2",
    "static3",
    "stream",
    "tv",
    "upload",
    "video",
    "vod",
    "www",
)


HOST_RE = re.compile(r"(?i)\b(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+filimo\.com\b")
URL_RE = re.compile(r"""(?i)\bhttps?://[^\s"'<>\\]+""")


def fetch_text(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(req, timeout=30) as response:
        return response.read().decode("utf-8", "replace")


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
    for match in HOST_RE.findall(text):
        host = normalize_host(match)
        if host:
            hosts.add(host)


def add_urls_from_text(urls, hosts, text):
    for match in URL_RE.findall(text):
        parsed = urllib.parse.urlsplit(match.rstrip(".,);]"))
        host = normalize_host(parsed.netloc)
        if host:
            hosts.add(host)
            urls.add(urllib.parse.urlunsplit((parsed.scheme.lower(), host, parsed.path, parsed.query, "")))


def load_seed_hosts(hosts):
    config = ROOT_DIR / "config" / "domains.txt"
    if config.exists():
        add_hosts_from_text(hosts, config.read_text(encoding="utf-8", errors="replace"))
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


def load_certspotter(hosts):
    for root in ROOT_DOMAINS:
        url = f"https://api.certspotter.com/v1/issuances?domain={urllib.parse.quote(root)}&include_subdomains=true&expand=dns_names"
        try:
            data = json.loads(fetch_text(url))
        except Exception as exc:
            print(f"warning: certspotter failed for {root}: {exc}", file=sys.stderr)
            continue
        for item in data:
            for name in item.get("dns_names", []):
                host = normalize_host(name)
                if host:
                    hosts.add(host)


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


def resolve_hosts(hosts):
    ips = set()
    resolved_hosts = set()
    for host in sorted(hosts):
        try:
            for family, _, _, _, sockaddr in socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM):
                if family != socket.AF_INET:
                    continue
                ip = ipaddress.ip_address(sockaddr[0])
                if ip.is_global:
                    ips.add(str(ip))
                    resolved_hosts.add(host)
        except socket.gaierror:
            continue
    return resolved_hosts, ips


def write_lines(path, values):
    path.write_text("".join(f"{value}\n" for value in sorted(values)), encoding="utf-8")


def main():
    hosts = set()
    urls = set()

    load_seed_hosts(hosts)
    load_crtsh(hosts)
    load_certspotter(hosts)
    load_urlscan(hosts, urls)
    crawl_seed_pages(hosts, urls)

    resolved_hosts, ips = resolve_hosts(hosts)
    host_urls = {f"https://{host}/" for host in hosts}

    write_lines(ROOT_DIR / "filimo-domains.txt", hosts)
    write_lines(ROOT_DIR / "filimo-hosts.txt", resolved_hosts)
    write_lines(ROOT_DIR / "filimo-urls.txt", urls | host_urls)
    write_lines(ROOT_DIR / "filimo-ips.txt", ips)
    write_lines(ROOT_DIR / "filimo-prefixes.txt", {f"{ip}/32" for ip in ips})

    print(f"domains: {len(hosts)}")
    print(f"resolved hosts: {len(resolved_hosts)}")
    print(f"urls: {len(urls | host_urls)}")
    print(f"ips: {len(ips)}")


if __name__ == "__main__":
    main()
