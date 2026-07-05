# managed-by=mohavise-iran-streaming-route-list
# project=iran-streaming-route-list
# service=iran-streaming
# compatibility-wrapper

/system scheduler
:if ([:len [find name="update-iran-streaming-outbound"]] > 0) do={ remove [find name="update-iran-streaming-outbound"] }
add name=update-iran-streaming-outbound start-time=04:01:00 interval=1d on-event="/system script run update-iran-streaming-outbound" policy=read,write,policy,test comment="managed-by=mohavise-iran-streaming-route-list service=iran-streaming"
