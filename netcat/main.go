package main

import (
	"context"
	"os"
	"os/exec"

	"golang.org/x/sys/unix"

	"k8s.io/klog"
	"k8s.io/kubernetes/pkg/kubelet/cm/cpuset"

	"github.com/openshift-kni/cnf-features-deploy/cnf-tests/pod-utils/pkg/node"
)

func main() {
	selfCPUs, err := node.GetSelfCPUs()
	if err != nil {
		klog.Fatalf("failed to get self allowed CPUs: %v", err)
	}

	mainThreadCPUs := selfCPUs.ToSlice()[0]
	mainThreadCPUSet := cpuset.NewCPUSet(mainThreadCPUs)
	klog.Infof("selected cpu is: %q", mainThreadCPUSet.String())

	port, ok := os.LookupEnv("NETCAT_PORT")
	if !ok {
		port = "12345"
	}
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
		klog.Fatalf("command returned with error: %v", err)
	}

	unixCPUSet := unix.CPUSet{}
	err = unix.SchedGetaffinity(cmd.Process.Pid, &unixCPUSet)
	if err != nil {
		klog.Fatalf("failed to get affinity error: %v", err)
	}
	klog.Infof("existing cpu set: %v", unixCPUSet)

	unixCPUSet.Zero()
	unixCPUSet.Set(mainThreadCPUs)
	err = unix.SchedSetaffinity(cmd.Process.Pid, &unixCPUSet)
	if err != nil {
		klog.Fatalf("failed to set affinity error: %v", err)
	}
	klog.Infof("new cpu set: %v", unixCPUSet)

	err = cmd.Wait()
	if err != nil {
		klog.Fatalf("command finished with error: %v", err)
	}

}
