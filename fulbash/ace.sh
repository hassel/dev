#!/bin/bash -u

AWK=/usr/bin/awk
GREP=/usr/bin/grep


CONF=ctx.conf
NAME=""


_get_vip_name () {
        $GREP "class-map match" $CONF | $AWK  {'print $3'}

}

_get_vip_addr_from_name () {
        $GREP "class-map $NAME" $CONF -A 1 | grep virtual | awk {'print $4,$6'}
}

for VIP in $(_get_vip_name); do
        NAME=$VIP
        echo $VIP is at $(_get_vip_addr_from_name)
done
