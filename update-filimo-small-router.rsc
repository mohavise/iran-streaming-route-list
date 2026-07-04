# managed-by=mohavise-mikrotik-filimo
# project=filimo-route-list
# do-not-edit-manually

:do {
    :local scriptName "update-filimo-small-router"
    :local scriptSource ":local fileName \"filimo-address-list.rsc\"
:local url \"https://raw.githubusercontent.com/mohavise/filimo-route-list/main/mikrotik-filimo-address-list.rsc\"
:local addressList \"filimo\"
:local backupList \"filimo-backup-before-update\"
:local minFileSize 100

:do {
    /tool fetch url=\$url dst-path=\$fileName mode=https
} on-error={
    :log warning \"Filimo update: download failed; keeping old address list\"
    :return
}

:delay 3

:if ([:len [/file find name=\$fileName]] = 0) do={
    :log warning \"Filimo update: downloaded file was not found; keeping old address list\"
    :return
}

:local fileSize [/file get \$fileName size]
:if (\$fileSize < \$minFileSize) do={
    :log warning \"Filimo update: downloaded file is too small or empty; keeping old address list\"
    /file remove \$fileName
    :return
}

/ip firewall address-list remove [find list=\$backupList]
:foreach item in=[/ip firewall address-list find list=\$addressList dynamic=no] do={
    :local address [/ip firewall address-list get \$item address]
    :do {
        /ip firewall address-list add list=\$backupList address=\$address
    } on-error={}
}

/ip firewall address-list remove [find list=\$addressList]

:do {
    /import file-name=\$fileName
} on-error={
    :log warning \"Filimo update: import failed; restoring old address list\"
    /ip firewall address-list remove [find list=\$addressList]
    :foreach item in=[/ip firewall address-list find list=\$backupList dynamic=no] do={
        :local address [/ip firewall address-list get \$item address]
        :do {
            /ip firewall address-list add list=\$addressList address=\$address
        } on-error={}
    }
    /ip firewall address-list remove [find list=\$backupList]
    /file remove \$fileName
    :return
}

:if ([:len [/ip firewall address-list find list=\$addressList]] = 0) do={
    :log warning \"Filimo update: new list has no entries; restoring old address list\"
    /ip firewall address-list remove [find list=\$addressList]
    :foreach item in=[/ip firewall address-list find list=\$backupList dynamic=no] do={
        :local address [/ip firewall address-list get \$item address]
        :do {
            /ip firewall address-list add list=\$addressList address=\$address
        } on-error={}
    }
    /ip firewall address-list remove [find list=\$backupList]
    /file remove \$fileName
    :return
}

/ip firewall address-list remove [find list=\$backupList]
/file remove \$fileName
:log info \"Filimo update: filimo address list updated successfully\""

    :if ([:len [/system script find name=$scriptName]] = 0) do={
        /system script add name=$scriptName dont-require-permissions=no policy=read,write,policy,test source=$scriptSource comment="managed-by=mohavise-mikrotik-filimo project=filimo-route-list"
    } else={
        /system script set [/system script find name=$scriptName] dont-require-permissions=no policy=read,write,policy,test source=$scriptSource comment="managed-by=mohavise-mikrotik-filimo project=filimo-route-list"
    }
}
