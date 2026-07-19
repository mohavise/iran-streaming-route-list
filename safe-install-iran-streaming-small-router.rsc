# managed-by=mohavise-mikrotik-iran-streaming-route-list
# project=mikrotik-iran-streaming-route-list
# service=iran-streaming
# single-orchestration-file

:do {
    :local scriptName "update-iran-streaming-outbound"
    :local scheduleName "update-iran-streaming-outbound"
    :local scriptSource ":local fileName \"iran-streaming-outbound.rsc\"
:local dnsBackup \"iran-streaming-dns-backup-before-update.rsc\"
:local url \"https://raw.githubusercontent.com/mohavise/mikrotik-iran-streaming-route-list/main/services/iran-streaming/output/list-all.rsc\"
:local addrList \"DST-IRAN-STREAMING-TO-OUTBOUND\"
:local marker \"iran-streaming:\"
:local minEntries 20

:log info \"Iran streaming outbound update: starting\"

:if ([:len [/file find name=\$fileName]] > 0) do={
    :do { /file remove [find name=\$fileName] } on-error={}
}
:if ([:len [/file find name=\$dnsBackup]] > 0) do={
    :do { /file remove [find name=\$dnsBackup] } on-error={}
}

:do {
    /ip dns static export file=\$dnsBackup where address-list=\$addrList and comment~\$marker
} on-error={
    :log error \"Iran streaming outbound update: backup failed; keeping current rules\"
    :return
}

:do {
    /tool fetch url=\$url dst-path=\$fileName check-certificate=yes-without-crl
} on-error={
    :log error \"Iran streaming outbound update: secure download failed; keeping current rules\"
    :return
}

:if ([:len [/file find name=\$fileName]] = 0) do={
    :log error \"Iran streaming outbound update: downloaded file not found; keeping current rules\"
    :return
}

:do {
    /import file-name=\$fileName verbose=yes dry-run
} on-error={
    :log error \"Iran streaming outbound update: downloaded file failed dry-run validation\"
    :do { /file remove [find name=\$fileName] } on-error={}
    :return
}

:do {
    /import file-name=\$fileName verbose=yes
} on-error={
    :log error \"Iran streaming outbound update: import failed; restoring backup\"
    :do { /ip dns static remove [find address-list=\$addrList comment~\$marker] } on-error={}
    :do { /import file-name=\$dnsBackup verbose=yes } on-error={
        :log error \"Iran streaming outbound update: backup restoration failed\"
    }
    :do { /file remove [find name=\$fileName] } on-error={}
    :return
}

:local entryCount [:len [/ip dns static find address-list=\$addrList comment~\$marker]]
:if (\$entryCount < \$minEntries) do={
    :log error (\"Iran streaming outbound update: only \" . \$entryCount . \" entries imported; restoring backup\")
    :do { /ip dns static remove [find address-list=\$addrList comment~\$marker] } on-error={}
    :do { /import file-name=\$dnsBackup verbose=yes } on-error={
        :log error \"Iran streaming outbound update: backup restoration failed\"
    }
    :do { /file remove [find name=\$fileName] } on-error={}
    :return
}

:do { /file remove [find name=\$fileName] } on-error={}
:if ([:len [/file find name=\$dnsBackup]] > 0) do={
    :do { /file remove [find name=\$dnsBackup] } on-error={}
}

:log info (\"Iran streaming outbound update: completed with \" . \$entryCount . \" entries\")"

    :if ([:len [/system script find name=$scriptName]] = 0) do={
        /system script add name=$scriptName dont-require-permissions=no policy=read,write,test source=$scriptSource comment="managed-by=mohavise-mikrotik-iran-streaming-route-list service=iran-streaming"
    } else={
        /system script set [find name=$scriptName] dont-require-permissions=no policy=read,write,test source=$scriptSource comment="managed-by=mohavise-mikrotik-iran-streaming-route-list service=iran-streaming"
    }

    :if ([:len [/system scheduler find name=$scheduleName]] = 0) do={
        /system scheduler add name=$scheduleName start-time=04:01:00 interval=1d on-event="/system script run update-iran-streaming-outbound" policy=read,write,test comment="managed-by=mohavise-mikrotik-iran-streaming-route-list service=iran-streaming"
    } else={
        /system scheduler set [find name=$scheduleName] start-time=04:01:00 interval=1d on-event="/system script run update-iran-streaming-outbound" policy=read,write,test comment="managed-by=mohavise-mikrotik-iran-streaming-route-list service=iran-streaming"
    }

    /system script run $scriptName
} on-error={
    :log error "Iran streaming outbound installer: unexpected error"
}
