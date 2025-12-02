FROM debian:testing AS mv_data
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential ca-certificates git
RUN git clone --depth=1 https://github.com/gardenlinux/mv_data
RUN make -C mv_data install

FROM debian:testing AS datefudge
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential ca-certificates git
RUN git clone --branch debian/1.26 --depth=1 https://salsa.debian.org/debian/datefudge.git
RUN make -C datefudge install

FROM debian:testing AS resizefat32
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential ca-certificates git
RUN git clone https://github.com/gardenlinux/resizefat32
RUN make -C resizefat32 install

FROM debian:testing

LABEL org.opencontainers.image.source="https://github.com/gardenlinux/builder"
LABEL org.opencontainers.image.description="Builder for Garden Linux"

COPY pkg.list /pkg.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $(cat /pkg.list) && rm /pkg.list
COPY --from=mv_data /usr/bin/mv_data /usr/bin/mv_data
COPY --from=datefudge /usr/lib/datefudge/datefudge.so /usr/lib/datefudge/datefudge.so
COPY --from=datefudge /usr/bin/datefudge /usr/bin/datefudge
COPY --from=resizefat32 /usr/bin/resizefat32 /usr/bin/resizefat32
RUN curl "https://github.com/gardenlinux/aws-kms-pkcs11/releases/download/latest/aws_kms_pkcs11-$(dpkg --print-architecture).so" -sLo "/usr/lib/$(uname -m)-linux-gnu/pkcs11/aws_kms_pkcs11.so"
COPY builder /builder
RUN python3 -m pip install --break-system-packages -r "/builder/requirements.txt" --root-user-action ignore
RUN mkdir /builder/cert
COPY setup_namespace /usr/sbin/setup_namespace
RUN curl -sSLf https://github.com/gardenlinux/seccomp_fake_xattr/releases/download/latest/seccomp_fake_xattr-$(uname -m).tar.gz \
	| gzip -d \
	| tar -xO seccomp_fake_xattr-$(uname -m)/fake_xattr > /usr/bin/fake_xattr \
	&& chmod +x /usr/bin/fake_xattr
RUN mkdir /tmp/sbsign \
	&& cd /tmp/sbsign \
	&& curl -sSLf https://github.com/gardenlinux/package-sbsigntool/releases/download/0.9.4-3.2gl0/build.tar.xz.0000 | xz -d | tar -x \
	&& dpkg -i sbsigntool_*_$(dpkg --print-architecture).deb
RUN echo 'root:1:65535' | tee /etc/subuid /etc/subgid > /dev/null
ENTRYPOINT [ "/usr/sbin/setup_namespace" ]
