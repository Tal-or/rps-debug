# RPS Debug
A small go program to test rps functionality for low latency sensitive telecommunication.
The specific RPS configuration are applied by cluster-node-tuning-operator:
https://github.com/openshift/cluster-node-tuning-operator 

## How it works
The test runs oslat and netcat inside a pod in the same container.
The test made sure that netcat uses the same cores as oslat does. 

User should send traffic to the netcat server via a netcat client as follows:
`netcat <node-ip> 30263`

A packet that being sent to the server triggers an interrupt on the NIC which attached to the pod, which in turn triggers a software interrupt, that **normally** would be handled by the same core where netcat is running.
But, RPS configure in such way that network interrupts should be handled by the [reserved](https://github.com/openshift/cluster-node-tuning-operator/blob/master/docs/performanceprofile/performance_profile.md#cpu) cores, so no interrupts should be seen in the core where netcat is running.
Since oslat is also running on the same core as netcat, we should expect no major latency measurement if RPS configured correctly, and if we do, it means something in the RPS configuration is wrong or broken.
