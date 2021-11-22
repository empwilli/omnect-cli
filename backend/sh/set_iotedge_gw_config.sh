#!/bin/bash

# include shared functions
. /ics-dm-sh/functions

d_echo ${0}

function usage() {
    echo "Usage: $0 -c identity_config -e edge_device_cert -k edge_device_cert_key -r root_cert -w wic_image" 1>&2; exit 1;
}

set -o errexit   # abort on nonzero exitstatus
set -o pipefail  # don't hide errors within pipes

while getopts "c:e:k:r:w:" opt; do
    case "${opt}" in
        c)
            c=${OPTARG}
            ;;
        e)
            e=${OPTARG}
            ;;
        k)
            k=${OPTARG}
            ;;
        r)
            r=${OPTARG}
            ;;
        w)
            w=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${c}" ] || [ -z "${e}" ] || [ -z "${k}" ] || [ -z "${r}" ] || [ -z "${w}" ]; then
    usage
fi

d_echo "c = ${c}"
d_echo "e = ${e}"
d_echo "k = ${k}"
d_echo "r = ${r}"
d_echo "w = ${w}"

[[ ! -f ${w} ]] && error "input device image not found"   && exit 1
[[ ! -f ${c} ]] && error "input file \"${c}\" not found"  && exit 1
[[ ! -f ${e} ]] && error "input file \"${e}\" not found"  && exit 1
[[ ! -f ${k} ]] && error "input file \"${k}\" not found"  && exit 1
[[ ! -f ${r} ]] && error "input file \"${r}\" not found"  && exit 1

# this script enforces a default placement of certs, e.g.
# [trust_bundle_cert]
# # root ca:
# trust_bundle_cert = "file:///var/secrets/trust-bundle.pem"
# [edge_ca]
# # device cert + key:
# cert = "file:///var/secrets/edge-ca.pem"
# pk = "file:///var/secrets/edge-ca.key.pem"

uuid_gen

p=etc
read_in_partition

# copy identity config
d_echo "e2cp ${c} /tmp/${uuid}/${p}.img:/upper/aziot/config.toml"
e2mkdir /tmp/${uuid}/${p}.img:/upper/aziot
e2cp ${c} /tmp/${uuid}/${p}.img:/upper/aziot/config.toml

config_hostname ${c}
write_back_partition

# create/append to ics_dm_first_boot.sh in factory partition
# activate identity config on first boot if enrollment demo is not installed
p=factory
read_in_partition
# for the following cp redirect stderr -> stdout, since it is possible that this file doesnt exist
e2cp /tmp/${uuid}/${p}.img:/ics_dm_first_boot.sh /tmp/${uuid}/icsd_dm_first_boot.sh 2>&1
echo "iotedge config apply" >>  /tmp/${uuid}/ics_dm_first_boot.sh
e2cp /tmp/${uuid}/ics_dm_first_boot.sh /tmp/${uuid}/${p}.img:/ics_dm_first_boot.sh
write_back_partition

# copy root ca cert,  device cert and key
# @todo refine how we use cert parition
p=data
read_in_partition
d_echo e2cp ${r} /tmp/${uuid}/${p}.img:/var/secrets/trust-bundle.pem
e2mkdir /tmp/${uuid}/${p}.img:/var/secrets
e2cp -P 644 ${r} /tmp/${uuid}/${p}.img:/var/secrets/trust-bundle.pem
d_echo e2cp ${e} /tmp/${uuid}/${p}.img:/var/secrets/edge-ca.pem
e2cp -P 644 ${e} /tmp/${uuid}/${p}.img:/var/secrets/edge-ca.pem
d_echo e2cp ${k} /tmp/${uuid}/${p}.img:/var/secrets/edge-ca.key.pem
e2cp -P 644  ${k} /tmp/${uuid}/${p}.img:/var/secrets/edge-ca.key.pem
write_back_partition
