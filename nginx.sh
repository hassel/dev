#!/bin/bash -u
#
# Carl 
# retard status script
# Kambi 2014

## VAR
UPSTREAMS="/status/upstreams"
SERVERZONE="/status/server_zones"
UPSTREAMCONF="/upstream_conf"
LB=""
UP=""
ID=""
STATUS="0"
CONFIG="0"
SET="0"
NODEID=""
CSTATE=""
STATE=""
NODEID=""
SERVEZONETOT=""
SERVEZONE1xx=""
SERVEZONE2xx=""
SERVEZONE3xx=""
SERVEZONE4xx=""
SERVEZONE5xx=""
ZONE=""
BACKENDDOWNTIME=""
## BIN
CURL=/usr/bin/curl 
AWK=/usr/bin/awk
JQ=/usr/bin/jq
MKTEMP=/bin/mktemp
ECHO="/bin/echo -e"


## FUNC

#_create_workdir () {
#        $MKTEMP
#}

## Get upstrams in to array
_get_upstreams () {
        $CURL -s "$LB$UPSTREAMS" | $JQ 'keys | .[]' | sed s/\"//g
}

## Get upstream http statistics 
_get_upstream_stat_http () {
        UNODETOT=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/responses/total")
        UNODE1xx=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/responses/1xx")
        UNODE2xx=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/responses/2xx")
        UNODE3xx=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/responses/3xx")
        UNODE4xx=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/responses/4xx")
        UNODE5xx=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/responses/5xx")
}


## Get upstream traffic statistics 
_get_upstream_stat_traffic () {
        UNODETXB=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/sent")
        UNODERXB=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/received")
}

## Get serverzones in to array
_get_server_zones () {
        $CURL -s "$LB$SERVERZONE" | $JQ 'keys | .[]' | sed s/\"//g
}

## Get serverzone http statistics 
_get_server_zone_stat_http () {
        SERVEZONETOT=$($CURL -s "$LB$SERVERZONE/$ZONE/responses/total")
        SERVEZONE1xx=$($CURL -s "$LB$SERVERZONE/$ZONE/responses/1xx")
        SERVEZONE2xx=$($CURL -s "$LB$SERVERZONE/$ZONE/responses/2xx")
        SERVEZONE3xx=$($CURL -s "$LB$SERVERZONE/$ZONE/responses/3xx")
        SERVEZONE4xx=$($CURL -s "$LB$SERVERZONE/$ZONE/responses/4xx")
        SERVEZONE5xx=$($CURL -s "$LB$SERVERZONE/$ZONE/responses/5xx")
}

## Get Serverzone traffic statistics
_get_server_zone_stat_traffic () {
        SERVERZONERXB=$($CURL -s $LB$SERVERZONE/$ZONE/received)
        SERVERZONETXB=$($CURL -s $LB$SERVERZONE/$ZONE/sent)
}
_get_upstream_backend_id () {
        $CURL -s "$LB$UPSTREAMS/$UP" | $JQ 'keys | .[]' >> /dev/null 2>&1
        if [ $? != "0" ]; then
                echo ERROR
                exit 1
        fi
        $CURL -s "$LB$UPSTREAMS/$UP" | $JQ 'keys | .[]' | sed s/\"//g
}
_get_upstream_backend_id_status () {
        BACKENDSTATUS=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/state" | sed s/\"//g)
}
_get_upstream_backend_id_downtime () {
        BACKENDDOWNTIME=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/downtime")
}

_get_upstream_backend_id_status_ip () {
        BACKENDIP=$($CURL -s "$LB$UPSTREAMS/$UP/$ID/server" | sed s/\"//g)
}
_get_upstream_conf () {
        BACKENDCONFIG=$($CURL -s "$LB$UPSTREAMCONF?upstream=$UP&id=$ID" )
}
_set_upstream_conf () {
        BACKENDCONFIG=$($CURL -s "$LB$UPSTREAMCONF?upstream=$UP&id=$ID&$STATE=" )
} 
_filthy_humans () {
         $AWK '{
          sum=$1 ; hum[1024**3]="Gb";hum[1024**2]="Mb";hum[1024]="Kb"; for (x=1024**3; x>=1024; x/=1024){
            if (sum>=x) { printf "%.2f %s\n",sum/x,hum[x];break } 
              }
         }'
}
_config_status_upstream_all () {
        for x in $(_get_upstreams); 
        do
                UP=$x
                echo -e "\E[32m\E[1m*  \E[0m Upstream :$UP"
                for y in $(_get_upstream_backend_id)
                do
                        ID=$y
                        _get_upstream_conf
                        _get_upstream_backend_id_status
                        if [ "$BACKENDSTATUS" = "up" ];
                                then
                                        #echo -e "\E[32m\E[1m-  \E[0m Config :$BACKENDCONFIG Health \E[34m\E[1m[\E[32m $BACKENDSTATUS \E[34m]\E[0m"
                                        echo -e "\E[32m\E[1m|  \E[0m Config :$BACKENDCONFIG \E[32m\E[1m|\E[0mHealth \E[34m\E[1m[\E[32m $BACKENDSTATUS \E[34m]\E[0m"
                                else
                                        echo -e "\E[31m\E[1m|  \E[0m Config :$BACKENDCONFIG \E[31m\E[1m|\E[0mHealth \E[34m\E[1m[\E[31m $BACKENDSTATUS \E[34m]\E[0m"
                        fi
                 done

        done
}
#_status_upstream_all () {
#        for x in $(_get_upstreams); 
#        do
#                UP=$x
#                echo -e "\E[32m\E[1m*  \E[0m $UP"
#                for y in $(_get_upstream_backend_id)
#                do
#                        ID=$y
#                        _get_upstream_backend_id_status
#                        if [ "$BACKENDSTATUS" = "up" ];
#                                then
#                                        echo -e "\E[32m\E[1m|  \E[0m State \E[34m\E[1m[\E[32m $BACKENDSTATUS \E[34m]\E[0m"
#                                else
#                                        echo -e "\E[31m\E[1m|  \E[0m State \E[34m\E[1m[\E[31m $BACKENDSTATUS \E[34m]\E[0m"
#                        fi
#                 done
#
#        done
#}
_show_upstream_status () {
        echo -e "\E[32m\E[1m*  \E[0m Upstream : $UP"
        for x in $(_get_upstream_backend_id);
        do
                ID=$x
                if [ $ID = "ERROR" ]; then
                        echo -e "\E[31m\E[1m* *  \E[0m Upstream :not found"
                        break
                        exit 1
                fi
                _get_upstream_backend_id_status_ip
                _get_upstream_backend_id_status
                _get_upstream_backend_id_downtime
                if [ "$BACKENDSTATUS" = "up" ];
                then
                        _get_upstream_stat_traffic
                        _get_upstream_stat_http
                        echo -e "\E[32m\E[1m|  \E[0m Upstream-server :$BACKENDIP Health \E[34m\E[1m[\E[32m $BACKENDSTATUS \E[34m]\E[0m Downtime : $BACKENDDOWNTIME"
                        _compile_upstream_stats
                else
                        echo -e "\E[31m\E[1m|  \E[0m Upstream-server :$BACKENDIP Health \E[34m\E[1m[\E[31m $BACKENDSTATUS \E[34m]\E[0m Downtime : $BACKENDDOWNTIME"
                fi
        done
}
_show_upstream_config () {
        echo -e "\E[32m\E[1m*  \E[0m Upstream :$UP"
        for x in $(_get_upstream_backend_id);
        do
                ID=$x
                if [ $ID = "ERROR" ]; then
                        echo -e "\E[31m\E[1m* *  \E[0m Upstream :not found"
                        break
                        exit 1
                fi
                _get_upstream_conf
                echo -e "\E[33m\E[1m*  \E[0m Config :$BACKENDCONFIG"
        done
}
_change_upstream_config () {
        if [[ "$STATE" != "up" && "$STATE" != "down" ]]; then
                echo -e "\E[33m\E[1m*  \E[0m Argument up/down needed for -m"
                exit 1
        fi
        ID=$NODEID
        _get_upstream_conf
        if [ -z "$ID" ];
        then
                echo "Node ID required."
                echo "Use  "$(basename $0) -c upstream" to get nodeid"
                exit 1
        fi
        if [ "$(echo $BACKENDCONFIG | grep down -c)" = "0" ]; then
                CSTATE=up
        else 
                CSTATE=down
        fi
        if [ "$CSTATE" = "$STATE" ]; then
                echo -e "\E[33m\E[1m*  \E[0m Cant change state, state allready $CSTATE"
        else
                _get_upstream_conf
                echo -e "\E[33m\E[1m*  \E[0m Change in $UP from :$BACKENDCONFIG $CSTATE"
                _set_upstream_conf
                if [ $? = "0" ]; then
                        echo -e "\E[33m\E[1m*  \E[0m Change in $UP to :$BACKENDCONFIG $STATE \E[34m\E[1m[\E[32m OK \E[34m]\E[0m"
                else
                        echo -e "\E[33m\E[1m*  \E[0m Change in $UP error \E[34m\E[1m[\E[31m !! \E[34m]\E[0m"
                        exit 1
                fi

        fi
        exit 0
}

_compile_upstream_stats () {
        if [ "$UNODETXB" -le "1024" ];then

                echo -e "\E[33m\E[1m*  \E[0m No traffic for $UP/$ID, (passive node?)"
                        continue
                else 
                        echo -e "\E[32m\E[1m*  \E[0m ServerZone Stats for : $ZONE"
                        RX=$(echo $UNODERXB | _filthy_humans)
                        echo -e "\E[32m\E[1m|  \E[0m Traffic RX $RX"
                fi
                if [ "$UNODERXB" -le "1024" ];then
                        echo -e "\E[32m\E[1m*  \E[0m No traffic for $ZONE, (passive node?)"
                        continue
                else
                        TX=$(echo $UNODETXB | _filthy_humans)
                        echo -e "\E[32m\E[1m|  \E[0m Traffic TX $TX"
                        echo -e "\E[32m\E[1m*  \E[0m Responses:" 
                        echo -e "\E[32m\E[1m|  \E[0m HTTP 1xx $UNODE1xx | HTTP 2xx $UNODE2xx | HTTP 3xx $UNODE3xx | HTTP 4xx $UNODE4xx | HTTP 5xx  $UNODE5xx"
        fi
}

_compile_serverzone_stats () {
        if [ "$SERVERZONETXB" -le "1024" ];then

                echo -e "\E[33m\E[1m*  \E[0m No traffic for $ZONE, (passive node?)"
                continue
        else 
                echo -e "\E[32m\E[1m*  \E[0m ServerZone Stats for : $ZONE"
                RX=$(echo $SERVERZONERXB | _filthy_humans)
                echo -e "\E[32m\E[1m|  \E[0m Traffic RX : $RX"
        fi
        if [ "$SERVERZONERXB" -le "1024" ];then
                echo -e "\E[32m\E[1m*  \E[0m No traffic for $ZONE, (passive node?)"
                continue
        else
                TX=$(echo $SERVERZONETXB | _filthy_humans)
                echo -e "\E[32m\E[1m|  \E[0m Traffic TX : $TX"
                echo -e "\E[32m\E[1m*  \E[0m Responses:" 
                echo -e "\E[32m\E[1m|  \E[0m HTTP 1xx : $SERVEZONE1xx"
                echo -e "\E[32m\E[1m|  \E[0m HTTP 2xx : $SERVEZONE2xx"
                echo -e "\E[32m\E[1m|  \E[0m HTTP 3xx : $SERVEZONE3xx"
                echo -e "\E[32m\E[1m|  \E[0m HTTP 4xx : $SERVEZONE4xx"
                echo -e "\E[32m\E[1m|  \E[0m HTTP 5xx : $SERVEZONE5xx"
        fi
}
_status_all_server_zone () {
        for z in $(_get_server_zones); do
                ZONE=$z
                _get_server_zone_stat_traffic
                _get_server_zone_stat_http
                _compile_serverzone_stats
        done
}
_show_server_zone_status () {
         for z in $ZONE; do
                _get_server_zone_stat_traffic
                _get_server_zone_stat_http
                _compile_serverzone_stats
        done
 }

_main () {
        if [ "$STATUS" = "1" ]; then
                _show_upstream_status
                exit 0
        fi
        if [ "$CONFIG" = "1" ]; then
                if [ "$SET" = "1" ]; then
                        if [[ "$SET" = "1" && ! -z "$NODEID" ]]; then
                                echo 3
                                 _change_upstream_config
                                 exit 0
                        else
                                 echo Option -n requires argument -m
                                 exit 1
                        fi
                        exit 0
                fi
                _show_upstream_config
                exit 0
        fi
        if [ ! -z "$ZONE" ]; then
                _show_server_zone_status
                exit 0
        fi

        if [ -z "$UP" ]; then
                $ECHO
                $ECHO SECTION UPSTREAM 
                $ECHO
                _config_status_upstream_all
                $ECHO
                $ECHO SECTION SERVERZONES
                $ECHO
                _status_all_server_zone
                exit 0
        fi

}

 _get_opts(){
        while getopts ":h :l: :u: :c: :m: :n: :z: :live:" opt
        do
                case $opt in
                        h)
                                echo -e "\E[32m\E[1m*  \E[0m  Usage:"
                                echo -e "\E[32m\E[1m*  \E[0m    $(basename $0) [options]"
                                echo -e "\E[32m\E[1m*  \E[0m" 
                                echo -e "\E[32m\E[1m*  \E[0m  Status options:"
                                echo -e "\E[32m\E[1m*  \E[0m    -l              host (for full status)" 
                                echo -e "\E[32m\E[1m*  \E[0m    -u              upstream (get upstream status)"
                                echo -e "\E[32m\E[1m*  \E[0m    -c              upstream (get upstream config)"
                                echo -e "\E[32m\E[1m*  \E[0m    -z              serverzone (get zerverzone status)"
                                echo -e "\E[32m\E[1m*  \E[0m" 
                                echo -e "\E[32m\E[1m*  \E[0m  Nodify options:"
                                echo -e "\E[32m\E[1m*  \E[0m    -m              down/up (change state of an upstream backend)"
                                echo -e "\E[32m\E[1m*  \E[0m    -n              node id (use with -m and -c)"
                                echo -e "\E[32m\E[1m*  \E[0m" 
                                echo -e "\E[32m\E[1m*  \E[0m  Exampels:"
                                echo -e "\E[32m\E[1m*  \E[0m    $(basename $0) -l lbx.site.kambi.com -c upstream -n node -m down" 
                                echo -e "\E[32m\E[1m*  \E[0m    $(basename $0) -l lbx.site.kambi.com -z zone"
                                echo -e "\E[32m\E[1m*  \E[0m    $(basename $0) -l lbx.site.kambi.com -z upstream"
                                exit 0
                        ;;
                        l)
                                LB=$OPTARG
                        ;;
                        u)
                                UP=$OPTARG
                                STATUS=1
                        ;;
                        z)
                                ZONE=$OPTARG
                        ;;
                        c)
                                UP=$OPTARG
                                CONFIG=1
                        ;;
                        :)
                                echo "Option -$OPTARG requires an argument"
                                exit 1
                        ;;
                        m)
                                SET=1
                                STATE=$OPTARG
                        ;;
                        n)
                                NODEID=$OPTARG
                        ;;
                        live)
                                LIVE=1
                        ;;
                        \?)
                        echo "Invalid options"
                        ;;
                esac
        done
        _main
}
if [ "$#" -lt "1" ]; then
        _get_opts -h
else
        _get_opts $@
fi





