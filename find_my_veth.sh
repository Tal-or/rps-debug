#!/usr/bin/env bash

cnt_id=${1}

function is_cnt_share_network_with_host() {
    local pid=${1}
    nsenter -t "${pid}" -n ip link br-ex > /dev/null 2>&1
    return
}

if [[ -z $cnt_id ]]; then
  echo "please provide container id"
  exit 1
fi

pid="$(crictl inspect "${cnt_id}" | jq .info.pid)"

if is_cnt_share_network_with_host "${pid}"; then
  echo "container ${cnt_id} is sharing network with host"
  exit 0
fi

netns_link_indexes=$(nsenter -t "${pid}" -n ip -json link | jq ".[] | select(.link_index != null) | .link_index")

veth_array=()
for link_index in ${netns_link_indexes}; do
  container_veth=$(ip -j link | jq ".[] | select(.ifindex == ${link_index}) | .ifname" | tr -d '"')
  veth_array+=("${container_veth}")
done

if [[ ${#veth_array[@]} -eq 0 ]]; then
  echo "no veth found for cnt id ${cnt_id}"
  exit 0
fi

echo "the following veth's found for cnt id: ${cnt_id}"
for veth in "${veth_array[@]}"; do
  echo "${veth}"
done
