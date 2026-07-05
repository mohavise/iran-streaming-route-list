# Iran Streaming DNS Policy Routing for MikroTik

DNS-static-first RouterOS list updater for routing Iranian video, VOD, live TV, and streaming services through a custom outbound path.

```text
service domains -> /ip dns static type=FWD address-list -> DST-IRAN-STREAMING-TO-OUTBOUND -> mangle -> route target
```

This repository follows the same approach as `mikrotik-dns-policy-routing`: database first, generated MikroTik DNS static output, safe updater, and daily scheduler.

## Important Design

This repo does **not** use IP lists.

It uses MikroTik DNS static FWD rules like this:

```routeros
/ip dns static
add regexp="(^|.*\\.)filimo\\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:filimo.com"
```

When clients use the MikroTik router as DNS, matched domain resolutions are automatically added to the target address list by RouterOS.

## Structure

```text
safe-install-iran-streaming-small-router.rsc       root MikroTik entry point
services/iran-streaming/database/domains.txt      trusted service database
services/iran-streaming/output/list-domains.rsc   generated DNS static FWD rules
services/iran-streaming/output/list-all.rsc       generated standalone import file
services/iran-streaming/routeros/update.rsc       MikroTik updater script
services/iran-streaming/routeros/scheduler.rsc    MikroTik daily scheduler
scripts/build-iran-streaming.sh                   generator
scripts/discover-iran-streaming.py                public-domain discovery helper
.github/workflows/update.yml                      daily GitHub update workflow
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

## Safe Install

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/iran-streaming-route-list/main/safe-install-iran-streaming-small-router.rsc" dst-path=safe-install-iran-streaming-small-router.rsc mode=https
/import file-name=safe-install-iran-streaming-small-router.rsc
/file remove [find name=safe-install-iran-streaming-small-router.rsc]
```

The safe installer fetches:

```text
services/iran-streaming/routeros/update.rsc
services/iran-streaming/routeros/scheduler.rsc
```

Then it runs:

```routeros
/system script run update-iran-streaming-outbound
```

## Manual Install

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/iran-streaming-route-list/main/services/iran-streaming/routeros/update.rsc" dst-path=update-iran-streaming-outbound.rsc mode=https
/import file-name=update-iran-streaming-outbound.rsc
/system script run update-iran-streaming-outbound
```

## Scheduler Install

```routeros
/tool fetch url="https://raw.githubusercontent.com/mohavise/iran-streaming-route-list/main/services/iran-streaming/routeros/scheduler.rsc" dst-path=scheduler-update-iran-streaming-outbound.rsc mode=https
/import file-name=scheduler-update-iran-streaming-outbound.rsc
/file remove [find name=scheduler-update-iran-streaming-outbound.rsc]
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

The updater script:

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
services/iran-streaming/output/list-domains.rsc
services/iran-streaming/output/list-all.rsc
mikrotik-iran-streaming-address-list.rsc
```

## Generate Manually

```bash
./scripts/build-iran-streaming.sh
```

If Python is installed but not on your Git Bash `PATH`, pass it explicitly:

```bash
IRAN_STREAMING_PYTHON=/c/path/to/python.exe ./scripts/build-iran-streaming.sh
```
