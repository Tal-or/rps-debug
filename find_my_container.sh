#!/usr/bin/env bash

veth_name=${1}

if [[ -z $veth_name ]]; then
  echo "please provide a veth name"
  exit 1
fi

function is_cnt_share_network_with_host() {
    local pid=${1}
    nsenter -t "${pid}" -n ip link br-ex > /dev/null 2>&1
    return
}

# get containers ids
cnt_ids=$(crictl ps | tail -n +2   | awk '{print $1}')
cnt_pid_to_id_map=()

# create a map of container's pid<>id pairs
for id in ${cnt_ids}; do
  cnt_pid_to_id_map["$(crictl inspect "${id}" | jq .info.pid)"]="${id}"
done

for pid in "${!cnt_pid_to_id_map[@]}"; do
    if is_cnt_share_network_with_host "${pid}"; then
      continue
    fi
    netns_link_indexes=$(nsenter -t "${pid}" -n ip -json link | jq ".[] | select(.link_index != null) | .link_index")

  for link_index in ${netns_link_indexes}; do
    container_veth=$(ip -j link | jq ".[] | select(.ifindex == ${link_index}) | .ifname" | tr -d '"')
    if [[ "${container_veth}" == "${veth_name}" ]]; then
      echo -e "container found!\n container id: ${cnt_pid_to_id_map[${pid}]}"
      exit 0
    fi
  done
done

echo "no container found for veth: ${veth_name}"
