#!/bin/bash -u
# 
# omg lol
# please help me to find out if we fucked up internaly externaly or both !!!1
# Hassel - 2013
#

# enter yer "main" domain for fetching internal ns records
INT_DOMAIN="example.com"

DIG=/usr/bin/dig
NS_INT_ROOT="ns.example.com"
REF="217.75.96.11 8.8.8.8"

_get_int_ns(){
        $DIG ns $INT_DOMAIN +short
}
_get_ext_ns(){
        domain=$(echo $@ | awk -F . '{ print $(NF-1) "." $NF }')
        $DIG ns $domain +short
}
_ext_recursion(){
        $DIG $@ +short | sort
}
_internal_authoritative(){
        $DIG -p53 +short @$NS $@ | sort
}
_root_int(){
        $DIG -p53 +short @$NS_INT_ROOT $@ | sort
}
_internal_recursive(){
        $DIG -p54 +short @$NS $@ | sort
}
_compare_external_internal(){
        echo -e "\E[32m\E[1m*  \E[0m Record/domain doesn't seem to be owned by us (internaly)                                             \E[34m\E[1m[\E[33m !! \E[34m]\E[0m" 
        echo -e "\E[32m\E[1m*  \E[0m Fetching in ns from interwebz"
        EXT_NS=$(_get_ext_ns $@)
        if [ -z "$EXT_NS" ]; then
                echo -e "\E[32m\E[1m*  \E[0m Record/domain doesn't seem to owned by anyone ?                                             \E[34m\E[1m[\E[33m !! \E[34m]\E[0m"
                exit 1
        fi
        INT_NS=$(_get_int_ns)
        echo -e "\E[32m\E[1m*  \E[0m Done" 
        for NS in $INT_NS; do
                for QUERY in $EXT_NS; do
                        if [ "$(_internal_recursive $@)" == "$(_ext_recursion $@ @$QUERY)" ];
                                then 
                                        echo -e "\E[32m\E[1m*  \E[0m Recrusion successfull for $@ (for $NS via $QUERY)    \E[34m\E[1m[\E[32m ok \E[34m]\E[0m"
                                fi
                done
        done
}
_compare_internal_external(){
        EXT_NS=$(echo $REF)
        INT_NS=$(_get_int_ns)
        for NS in $INT_NS; do
                for QUERY in $EXT_NS; do
                        if [ "$(_internal_recursive $@)" == "$(_ext_recursion $@ @$QUERY)" ];
                                then 
                                        echo -e "\E[32m\E[1m*  \E[0m Recrusion successfull for $@ (via $QUERY)    \E[34m\E[1m[\E[32m ok \E[34m]\E[0m"
                                else
                                        if [ -z "$(_ext_recursion $@ @$QUERY)" ];
                                        then
                                                echo -e "\E[32m\E[1m*  \E[0m Record NOT visible on the interewbz   \E[34m\E[1m[\E[33m !! \E[34m]\E[0m"
                                                break
                                        else
                                                echo -e "\E[32m\E[1m*  \E[0m Diff between internal & external answer."
                                                echo -e "\E[32m\E[1m*  \E[0m External "$(_ext_recursion $@ @$QUERY)"  \E[34m\E[1m[\E[33m !! \E[34m]\E[0m"
                                                echo -e "\E[32m\E[1m*  \E[0m Internal "$(_internal_recursive $@)"        \E[34m\E[1m[\E[33m !! \E[34m]\E[0m"
                                        fi

                                fi
                done
        done
}


_compare_internal_unbound_nsd(){
                echo -e "\E[32m\E[1m*  \E[0m Record seems to owned by you                                                \E[34m\E[1m[\E[32m ok \E[34m]\E[0m"
                INT_NS=$(_get_int_ns)
                for NS in $INT_NS;
                do
                        if [ "$(_internal_recursive $@)" == "$(_root_int $@)"  ]; then
                                echo -e "\E[32m\E[1m*  \E[0m Unbound at $NS in sync with $NS_INT_ROOT                   \E[34m\E[1m[\E[32m ok \E[34m]\E[0m"
                        else
                                echo -e "\E[32m\E[1m*  \E[0m Unbound at $NS NOT in sync with $NS_INT_ROOT               \E[34m\E[1m[\E[33m !! \E[34m]\E[0m" 
                        fi
                        if [ "$(_internal_authoritative $@)" == "$(_root_int $@)" ]; then
                                echo -e "\E[32m\E[1m*  \E[0m NSD at $NS in sync with $NS_INT_ROOT                       \E[34m\E[1m[\E[32m ok \E[34m]\E[0m"
                        else
                                echo -e "\E[32m\E[1m*  \E[0m NSD at $NS NOT in sync with $NS_INT_ROOT                   \E[34m\E[1m[\E[33m !! \E[34m]\E[0m"
                        fi
                done
}
_full(){
        if  [ -z "$(_root_int $@)" ];
        then
                _compare_external_internal $@
        else
                _compare_internal_unbound_nsd $@
                _compare_internal_external $@
fi
}

_get_opts(){
                while getopts :i:e:a:h opt; do
                        case $opt in
                                a)
                                        _full $2
                                        ;;
                                i)
                                        _compare_internal_unbound_nsd $2
                                        ;;
                                e)
                                        _compare_internal_external $2
                                        ;;
                                h)
                                        echo -e "\E[32m\E[1m*  \E[0m  Usage:"
                                        echo -e "\E[32m\E[1m*  \E[0m  $(basename $0) -i record.domain (internal check)" 
                                        echo -e "\E[32m\E[1m*  \E[0m  $(basename $0) -e record.domain (external check)"
                                        echo -e "\E[32m\E[1m*  \E[0m  $(basename $0) -a record.domain (check both)"
                                        echo -e "\E[32m\E[1m*  \E[0m  $(basename $0) -h (this message)"
                                        echo -e "\E[32m\E[1m*  \E[0m " 
                                        ;;
                                *)
                                        _get_opts -h
                                        ;;
                                ?)
                                        echo -e  "\E[32m\E[1m*  \E[0m " DERP
                                        ;;
                        esac
                done
 }

if [ "$#" -lt "1" ]; then
        _get_opts -h
  else
        _get_opts $@
fi
