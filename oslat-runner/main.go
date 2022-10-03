package main

import (
	"context"
	"flag"
	"fmt"
	"github.com/Tal-or/rps-debug/pkg/netcat/affinityoption"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"time"

	"k8s.io/klog"
	"k8s.io/kubernetes/pkg/kubelet/cm/cpuset"

	"golang.org/x/sys/unix"

	"github.com/openshift-kni/cnf-features-deploy/cnf-tests/pod-utils/pkg/node"
)

const (
	oslatBinary      = "/usr/bin/oslat"
	mainThreadCPUEnv = "MAIN_THREAD_CPU"
)

func main() {
	klog.InitFlags(nil)

	var oslatStartDelay = flag.Int("oslat-start-delay", 0, "Delay in second before running the oslat binary, can be useful to be sure that the CPU manager excluded the pinned CPUs from the default CPU pool")
	var rtPriority = flag.String("rt-priority", "1", "Specify the SCHED_FIFO priority (1-99)")
	var runtime = flag.String("runtime", "10m", "Specify test duration, e.g., 60, 20m, 2H")
	var ncAffinity = flag.String("nc-affinity", "none", "Specify nc process's core affinity. Options: none, management, measurement")
	flag.Parse()

	selfCPUs, err := node.GetSelfCPUs()
	if err != nil {
		klog.Fatalf("failed to get self allowed CPUs: %v", err)
	}

	if selfCPUs.Size() < 2 {
		klog.Fatalf("the amount of requested CPUs less than 2, the oslat requires at least 2 CPUs to run")
	}

	mainThreadCPUs := selfCPUs.ToSlice()[0]
	siblings, err := node.GetCPUSiblings(mainThreadCPUs)
	if err != nil {
		klog.Fatalf("failed to get main thread CPU siblings: %v", err)
	}
	cpusForLatencyTest := selfCPUs.Difference(cpuset.NewCPUSet(siblings...))
	mainThreadCPUSet := cpuset.NewCPUSet(mainThreadCPUs)
	if err := os.Setenv(mainThreadCPUEnv, mainThreadCPUSet.String()); err != nil {
		klog.Fatalf("failed to set %s env variable", mainThreadCPUEnv)
	}
	klog.Infof("set %s environment variable to %s", mainThreadCPUEnv, mainThreadCPUSet.String())

	affinity := affinityoption.Parse(*ncAffinity)
	if affinity != affinityoption.None {
		port, ok := os.LookupEnv("NETCAT_PORT")
		if !ok {
			port = "12345"
		}
		klog.Infof("netcat port: %q", port)

		ncCmd := []string{
			"--listen",
			"--keep-open",
			"-p",
			port,
		}

		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()

		cmd := exec.CommandContext(ctx, "nc", ncCmd...)
		klog.Infof("running %s", cmd.String())
		cmd.Stdout = os.Stdout
		err = cmd.Start()
		if err != nil {
			klog.Errorf("command finished with error: %v", err)
		}

		ncCPUAffinity := unix.CPUSet{}
		if affinity == affinityoption.Management {
			ncCPUAffinity.Set(mainThreadCPUs)
		} else {
			ncCPUAffinity.Set(cpusForLatencyTest.ToSlice()[0])
		}

		err = unix.SchedSetaffinity(cmd.Process.Pid, &ncCPUAffinity)
		if err != nil {
			klog.Fatalf("failed to set affinity; error %v", err)
		}

		affinitySet, err := unixToCPUSet(ncCPUAffinity)
		if err != nil {
			klog.Fatalf("err: %v", err)
		}
		klog.Infof("command %s affinity is: %v", cmd.String(), affinitySet.String())
	}

	err = node.PrintInformation()
	if err != nil {
		klog.Fatalf("failed to print node information: %v", err)
	}

	if *oslatStartDelay > 0 {
		klog.Infof("waiting %d seconds before start", *oslatStartDelay)
		time.Sleep(time.Duration(*oslatStartDelay) * time.Second)
	}

	oslatArgs := []string{
		"--duration", *runtime,
		"--rtprio", *rtPriority,
		"--cpu-list", cpusForLatencyTest.String(),
		"--cpu-main-thread", mainThreadCPUSet.String(),
	}

	klog.Infof("Running the oslat command with arguments %v", oslatArgs)
	out, err := exec.Command(oslatBinary, oslatArgs...).CombinedOutput()
	if err != nil {
		klog.Fatalf("failed to run oslat command; out: %s; err: %v", out, err)
	}

	klog.Infof("succeeded to run the oslat command: %s", out)
	klog.Flush()
}

func unixToCPUSet(unixSet unix.CPUSet) (cpuset.CPUSet, error) {
	cmd := exec.Command("/bin/sh", "-c", "grep processor /proc/cpuinfo | wc -l")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return cpuset.CPUSet{}, fmt.Errorf("failed to run command, out: %s; err: %v", out, err)
	}
	cpuCount, err := strconv.Atoi(strings.Trim(string(out), "\n"))
	if err != nil {
		return cpuset.CPUSet{}, err
	}

	var cpus []int
	for i := 0; i < cpuCount; i++ {
		if unixSet.IsSet(i) {
			cpus = append(cpus, i)
		}
	}
	return cpuset.NewCPUSet(cpus...), nil
}
