FROM arm64v8/ubuntu:18.04 AS build

RUN apt update && apt -y install git curl ceph

# Install go
RUN curl -sSL https://storage.googleapis.com/golang/go1.10.2.linux-arm64.tar.gz | gzip -dc | tar xf - -C /usr/local

ENV GOPATH /usr/src/go
ENV PATH /usr/local/go/bin:/usr/local/bin:/bin:/usr/bin

# Add source
WORKDIR /usr/src/go/src/github.com/kubernetes-incubator/external-storage
RUN git clone https://github.com/kubernetes-incubator/external-storage . && git checkout tags/rbd-provisioner-v0.1.0

# Build
RUN set -ex && cd /usr/src/go/src/github.com/kubernetes-incubator/external-storage/ceph/rbd \
    && env CGO_ENABLED=0 go build -a -ldflags '-extldflags "-static"' -o rbd-provisioner ./cmd/rbd-provisioner

# Generate the final image
FROM arm64v8/ubuntu:18.04

RUN apt update \
    && apt -y install ceph \
    && rm -rf /var/lib/apt/lists/*

# Copy the image from the builder image
COPY --from=build /usr/src/go/src/github.com/kubernetes-incubator/external-storage/ceph/rbd/rbd-provisioner /usr/local/bin

ENTRYPOINT ["/usr/local/bin/rbd-provisioner"]
