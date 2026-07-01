# managed-by=mohavise-mikrotik-filimo
# project=filimo-route-list
# do-not-edit-manually

:do {
    :local updateUrl "https://raw.githubusercontent.com/mohavise/filimo-route-list/main/update-filimo-small-router.rsc"
    :local schedulerUrl "https://raw.githubusercontent.com/mohavise/filimo-route-list/main/scheduler-update-filimo-small-router.rsc"
    :local updateFile "update-filimo-small-router.rsc"
    :local schedulerFile "scheduler-update-filimo-small-router.rsc"

    /tool fetch url=$updateUrl dst-path=$updateFile mode=https
    /import file-name=$updateFile
    /file remove [find name=$updateFile]

    /tool fetch url=$schedulerUrl dst-path=$schedulerFile mode=https
    /import file-name=$schedulerFile
    /file remove [find name=$schedulerFile]

    /system script run update-filimo-small-router
}
