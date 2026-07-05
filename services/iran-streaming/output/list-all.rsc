# managed-by=mohavise-mikrotik-iran-streaming-route-list
# project=mikrotik-iran-streaming-route-list
# service=iran-streaming
# List: Iranian streaming DNS static FWD rules
# RouterOS address-list: DST-IRAN-STREAMING-TO-OUTBOUND
# Source: services/iran-streaming/database/domains.txt
# do-not-edit-manually

/ip dns static
remove [find address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment~"iran-streaming:"]
:do { add regexp="(^|.*\.)anten\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:anten.ir" } on-error={}
:do { add regexp="(^|.*\.)aparat\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:aparat.com" } on-error={}
:do { add regexp="(^|.*\.)aparatkids\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:aparatkids.com" } on-error={}
:do { add regexp="(^|.*\.)filimo\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:filimo.com" } on-error={}
:do { add regexp="(^|.*\.)ifilmtv\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:ifilmtv.ir" } on-error={}
:do { add regexp="(^|.*\.)imvbox\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:imvbox.com" } on-error={}
:do { add regexp="(^|.*\.)irib\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:irib.ir" } on-error={}
:do { add regexp="(^|.*\.)lenz\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:lenz.ir" } on-error={}
:do { add regexp="(^|.*\.)mp4\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:mp4.ir" } on-error={}
:do { add regexp="(^|.*\.)namasha\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:namasha.com" } on-error={}
:do { add regexp="(^|.*\.)namava\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:namava.ir" } on-error={}
:do { add regexp="(^|.*\.)sabaidea\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:sabaidea.com" } on-error={}
:do { add regexp="(^|.*\.)sabavision\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:sabavision.com" } on-error={}
:do { add regexp="(^|.*\.)shabakema\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:shabakema.com" } on-error={}
:do { add regexp="(^|.*\.)tamasha\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:tamasha.com" } on-error={}
:do { add regexp="(^|.*\.)telewebion\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:telewebion.com" } on-error={}
:do { add regexp="(^|.*\.)televika\.com$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:televika.com" } on-error={}
:do { add regexp="(^|.*\.)tv\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:tv.ir" } on-error={}
:do { add regexp="(^|.*\.)tva\.ir$" type=FWD address-list=DST-IRAN-STREAMING-TO-OUTBOUND comment="iran-streaming:tva.ir" } on-error={}
