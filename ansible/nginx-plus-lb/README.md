# LB model for nginx

> This is a group-varliable yaml
> it should be located in /inventory/group_vars/group-name
 
## Group-specific vars
 site: location of the lb-cluster 
 machinetype: lb 
 ciphers: cipher list
 sysctl: sysctl settings

 Example:

```yaml
 site: lnd
 machinetype: lb
 ciphers: "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH"
 sysctl:
   net.ipv4.tcp_syncookies: 1                 
   net.ipv4.ip_forward: 1
   net.ipv4.tcp_sack: 0
   net.ipv4.tcp_timestamps: 0
  <snip>
```
##  Nginx-specific vars
 vips: list of vips to be setup. key will be the name of the config file.
 
## Eaxmple:

```yaml
 vips: 
   key1:
   key2:

 upstreams:
   key1:
   key2:

 probes:
   key1:
   key2:
```
##  VIP-key specific vars

### Example 

```yaml
vips:
   vip_name: 
      server_name: example.domain.ltd
      listen: listen-addr:port                      Only define port when L4 vip, L7 vips (http/https) only requires an address
      proto:                                        *If tcp is defined, no other protocols can be defined. If http|https is defined, https|http can also be defined.
        - https
        - http
        - tcp *
      prefix: conf|stream                           Config prefix, determins where in the core config should be included. Prefix "config" is used for L7 vips, "stream" for L4 vips.
      ssl_crt: /etc/ssl/cert.pem                    Certificate in pem format
      ssl_key: /etc/ssl/key.pem                     Key in pem format
      ssl_staple: /etc/ssl/gd_bundle.crt            When defined, oscp will be enabled. Note that external resolving needs to work for this to work. If oscp stapeling is not wanted, leav the var undefined.
    probe: monitoring-foo                           Name of the health check for the FIRST listed location configured. Needs to match with the configured probe name
    probe_uri: /bar/json                            uri for the health check to probe for response/data
    locations:                                      List of locations, location_1 location_2 etc.
      location_1:                                   Readable comment, needs to be uniq
        context: /foo.xml                           Context-path to be accessed
        backend: sfarm-foo                          Name of the backend-group configured to serve the specific location, needs to match with the configured upstream. 
      location_2:                                   If you're using multiple contexts to the same backend, make sure to use a list, else health-check logic wont work as expected
        context: 
          - /bar/                                   -||-
          - /baz/                                   -||-
        backend: sfarm-bar                          -||-
```
## Upstream specific vars.

### Example
```yaml
 upstreams: 
   upstream_name:                                   Name of the backend-group
    in_catalog: no|yes                              Information avalible in catalog ? If defined, no need to list backends below. If in_catalog is true. upstream_name needs to corlolate with the application (form the catalog)
    prefix: sfarm|tcp                               Config prefix, determins where in the core config should be included. Prefix "sfarm" is used for L7 vips, "tcp" for L4 vips.
    backends:
      - backendaddr:port                            backend ipv4 address & port
      - backendaddr:port                            -||- 
    algo: least_conn                                Algorithm for balance decisions
    probe: monitor-xml                              Name of the healt check configured, needs to match with the configured probe.
```

## Probe specific vars

### Example

```yaml
 probes:
  monitoring-foo:                                   Name of the probe/health check
    status: 200                                     Expected status code
    header: Content-Type = application/json         Expected Content-type
    body: '!~ "varnish"'                            Make sure "varnish" is not a part of the body.
``` 
  


###   Example L4 vip 
```yaml
 vips:
   vipname:
     server_name: mq.bru.domain.ltd
     listen: 10.10.10.10:61616
     proto:
      - tcp
     prefix: stream
     backend: sfarm-offering-mq

   sfarm-offering-mq:
     in_catalog: no
     prefix: tcp
     backends:
       - 10.10.10.11:61616
       - 10.10.10.12:61616
     algo: least_conn
     probe: 
```
###  Example L7 vip 
```yaml
 vips:
   api: 
      server_name: e4-api.domain.ltd
      listen: 185.63.76.8
      proto: 
        - https
        - http
      prefix: conf
      ssl_crt: /etc/ssl/wildcard_kambi_bundle.crt
      ssl_key: /etc/ssl/wildcard_kambi_bundle.key
      ssl_staple: /etc/ssl/gd_bundle.crt
    probe: monitoring-json
    probe_uri: /offering/api/v2/kambi/group.json
    locations:
      location_1:
        context: /crossdomain.xml
        backend: sfarm-offering
      location_2:
        context: /offering/
        backend: sfarm-offering

 upstreams:
   sfarm-offering:
     in_catalog: no
     prefix: sfarm
     backends:
       - 10.50.3.65:6081
       - 10.50.3.66:6081
     algo: hash $request_uri
     probe: monitoring-json

  sfarm-static:
    in_catalog: no 
    prefix: sfarm
    backends:
      - 10.50.3.65:6081
      - 10.50.3.66:6081
    algo: hash $request_uri
    probe: monitoring-xml
 probes:
   monitoring-xml:
     status: 200
     header: Content-Type = application/xml
     body: '!~ "varnish"'
   monitoring-json:
     status: 200
     header: Content-Type = application/json
     body: '!~ "varnish"'
```
