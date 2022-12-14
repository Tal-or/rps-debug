# build latency-test's runner binaries
FROM golang:1.18-alpine AS builder-latency-test-runners

ENV PKG_NAME=github.com/Tal-or/rps-debug
ENV PKG_PATH=/go/src/$PKG_NAME

RUN mkdir -p $PKG_PATH

COPY . $PKG_PATH/
WORKDIR $PKG_PATH
RUN go build -mod=vendor -o /oslat-runner oslat-runner/main.go


# Build latency-test binaries
FROM centos:7 as builder-latency-test-tools

ENV RT_TESTS_URL=https://git.kernel.org/pub/scm/utils/rt-tests/rt-tests.git/snapshot
ENV RT_TESTS_PKG=rt-tests-2.0

RUN yum install -y numactl-devel make gcc && \
    curl -O $RT_TESTS_URL/$RT_TESTS_PKG.tar.gz && \
    tar -xvf $RT_TESTS_PKG.tar.gz && \
    cd $RT_TESTS_PKG && \
    make oslat && \
    cp oslat /oslat

FROM centos:7

# python3 is needed for hwlatdetect
RUN curl -L https://forensics.cert.org/cert-forensics-tools-release-el7.rpm -o cert-forensics-tools-release-el7.rpm && \
    rpm -Uvh cert-forensics-tools-release*rpm && \
    yum --enablerepo=forensics install -y musl-libc iproute libhugetlbfs-utils libhugetlbfs numactl-libs ethtool ping nc

COPY --from=builder-latency-test-runners /oslat-runner /usr/bin/oslat-runner
COPY --from=builder-latency-test-tools /oslat /usr/bin/oslat

ENV SUITES_PATH=/usr/bin/

CMD ["/usr/bin/oslat-runner"]