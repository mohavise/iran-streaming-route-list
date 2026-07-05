# Iran Streaming DNS Policy Routing for MikroTik

DNS-static-first RouterOS list updater for routing Iranian video, VOD, live TV, and streaming services through a custom outbound path.

```text
service domains -> /ip dns static type=FWD address-list -> DST-IRAN-STREAMING-TO-OUTBOUND -> mangle -> route target
```

This repository follows a small database-first design: service domains, one generated RouterOS DNS static file, and one MikroTik orchestration installer.

## Important Design

This repo does **not** use IP lists.

It uses MikroTik DNS static FWD rules like this:

```routeros
/ip dns static
add regexp="(^|.*\\.)filimo\\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:filimo.com"
```

When clients use the MikroTik router as DNS, matched domain resolutions are automatically added to the target address list by RouterOS.

## Minimal Structure

```text
README.md                                           documentation
safe-install-iran-streaming-small-router.rsc       single MikroTik orchestration installer
services/iran-streaming/database/domains.txt       trusted service database
services/iran-streaming/output/list-all.rsc        generated DNS static FWD rules
scripts/build-iran-streaming.sh                    generator
scripts/discover-iran-streaming.py                 public-domain discovery helper
.github/workflows/update.yml                       daily GitHub update workflow
```

## RouterOS List Name

```text
DST-IRAN-STREAMING-TO-OUTBOUND
```

## Included Services

The source database starts with popular Iranian video and streaming platforms, including:

- Filimo
- Aparat
- Aparat Kids
- Namava
- Telewebion
- Anten
- Lenz
- Tamasha
- Namasha
- Shabakema
- IMVBox
- IRIB / iFilm / TV-related services
- related media/CDN domains such as Saba Idea and Saba Vision

Edit the main database here:

```text
services/iran-streaming/database/domains.txt
```

## Safe Install / Orchestration

This single file creates the update script, creates the daily scheduler, and runs the first update once:

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/mikrotik-iran-streaming-route-list/main/safe-install-iran-streaming-small-router.rsc" dst-path=safe-install-iran-streaming-small-router.rsc mode=https
/import file-name=safe-install-iran-streaming-small-router.rsc
/file remove [find name=safe-install-iran-streaming-small-router.rsc]
```

Created RouterOS objects:

```text
/system script name=update-iran-streaming-outbound
/system scheduler name=update-iran-streaming-outbound
```

Default schedule:

```text
04:01:00 daily
```

## MikroTik Requirements

Clients must use MikroTik as DNS, otherwise DNS static FWD address-list learning will not happen.

At minimum:

```routeros
/ip dns set allow-remote-requests=yes
```

Then force/hand out the router DNS to clients using DHCP or firewall DNS redirect rules.

## Policy Routing Example

Example only; adjust the routing table and gateway to your own design.

```routeros
/routing table add name=to-outbound fib
/ip firewall mangle add chain=prerouting dst-address-list=DST-IRAN-STREAMING-TO-OUTBOUND action=mark-routing new-routing-mark=to-outbound passthrough=no comment="Iran streaming to outbound"
/ip route add dst-address=0.0.0.0/0 gateway=<YOUR-OUTBOUND-GATEWAY> routing-table=to-outbound
```

## Update Safety

The update script created by the orchestration file:

1. exports current DNS static rules for backup
2. downloads the generated list
3. checks the file exists and is large enough
4. imports the new DNS static FWD rules
5. verifies the list is not empty
6. restores backup if import fails

Backup file:

```text
iran-streaming-dns-backup-before-update.rsc
```

## GitHub Automation

Workflow:

```text
.github/workflows/update.yml
```

It runs every day at `23:30 UTC` and can also be started manually from GitHub Actions.

Generated files:

```text
iran-streaming-domains.txt
iran-streaming-urls.txt
services/iran-streaming/output/list-all.rsc
```

## Generate Manually

```bash
./scripts/build-iran-streaming.sh
```

If Python is installed but not on your Git Bash `PATH`, pass it explicitly:

```bash
IRAN_STREAMING_PYTHON=/c/path/to/python.exe ./scripts/build-iran-streaming.sh
```
