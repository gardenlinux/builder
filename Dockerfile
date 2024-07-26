FROM debian:testing AS mv_data
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential ca-certificates git
RUN git clone --depth=1 https://github.com/gardenlinux/mv_data
RUN make -C mv_data install

FROM debian:testing AS aws-kms-pkcs11
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential awscli ca-certificates cmake git libcurl4-openssl-dev libengine-pkcs11-openssl libjson-c-dev libssl-dev libp11-kit-dev libp11-dev pkg-config zlib1g-dev
RUN git clone --depth=1 --recurse-submodules -b 1.11.315 https://github.com/aws/aws-sdk-cpp
RUN mkdir aws-sdk-cpp/.build && cd aws-sdk-cpp/.build && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DAWS_USE_CRYPTO_SHARED_LIBS=ON -DBUILD_ONLY="kms;acm-pca" .. && make -j "$(nproc)" install
RUN git clone --depth=1 -b v0.0.10 https://github.com/gardenlinux/aws-kms-pkcs11
RUN cd aws-kms-pkcs11 && make -j "$(nproc)" AWS_SDK_STATIC=y install
RUN cp "/usr/lib/$(uname -m)-linux-gnu/pkcs11/aws_kms_pkcs11.so" /aws_kms_pkcs11.so

FROM debian:testing AS datefudge
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential ca-certificates git
RUN git clone --branch debian/1.26 --depth=1 https://salsa.debian.org/debian/datefudge.git
RUN make -C datefudge install

FROM debian:testing

LABEL org.opencontainers.image.source="https://github.com/gardenlinux/builder"
LABEL org.opencontainers.image.description="Builder for Garden Linux"

COPY pkg.list /pkg.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $(cat /pkg.list) && rm /pkg.list
RUN cd /tmp \
&& curl -sSL "https://github.com/gardenlinux/package-openssl/releases/download/3.1.4-2gardenlinux0/openssl_3.1.4-2gardenlinux0_$(dpkg --print-architecture).deb" > openssl.deb \
&& dpkg -i openssl.deb \
&& rm openssl.deb
COPY --from=mv_data /usr/bin/mv_data /usr/bin/mv_data
COPY --from=aws-kms-pkcs11 /aws_kms_pkcs11.so /aws_kms_pkcs11.so
COPY --from=datefudge /usr/lib/datefudge/datefudge.so /usr/lib/datefudge/datefudge.so
COPY --from=datefudge /usr/bin/datefudge /usr/bin/datefudge
RUN mv /aws_kms_pkcs11.so "/usr/lib/$(uname -m)-linux-gnu/pkcs11/aws_kms_pkcs11.so"
COPY builder /builder
RUN mkdir /builder/cert
COPY setup_namespace /usr/sbin/setup_namespace
RUN curl -sSLf https://github.com/gardenlinux/seccomp_fake_xattr/releases/download/latest/seccomp_fake_xattr-$(uname -m).tar.gz \
	| gzip -d \
	| tar -xO seccomp_fake_xattr-$(uname -m)/fake_xattr > /usr/bin/fake_xattr \
	&& chmod +x /usr/bin/fake_xattr
RUN echo 'root:1:65535' | tee /etc/subuid /etc/subgid > /dev/null
ENTRYPOINT [ "/usr/sbin/setup_namespace" ]
