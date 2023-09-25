FROM debian:testing AS mv_data
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential ca-certificates git
RUN git clone --depth=1 https://github.com/nkraetzschmar/mv_data
RUN make -C mv_data install

FROM debian:testing AS aws-kms-pkcs11
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends build-essential awscli ca-certificates cmake git libcurl4-openssl-dev libengine-pkcs11-openssl libjson-c-dev libssl-dev libp11-kit-dev libp11-dev zlib1g-dev
RUN git clone --depth=1 --recurse-submodules -b 1.11.25 https://github.com/aws/aws-sdk-cpp
RUN mkdir aws-sdk-cpp/.build && cd aws-sdk-cpp/.build && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DBUILD_ONLY="kms;acm-pca" .. && make -j "$(nproc)" install
RUN git clone --depth=1 -b v0.0.10 https://github.com/JackOfMostTrades/aws-kms-pkcs11
RUN cd aws-kms-pkcs11 && make -j "$(nproc)" AWS_SDK_STATIC=y install
RUN cp "/usr/lib/$(uname -m)-linux-gnu/pkcs11/aws_kms_pkcs11.so" /aws_kms_pkcs11.so

FROM debian:testing
COPY pkg.list /pkg.list
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $(cat /pkg.list) && rm /pkg.list
COPY --from=mv_data /usr/bin/mv_data /usr/bin/mv_data
COPY --from=aws-kms-pkcs11 /aws_kms_pkcs11.so /aws_kms_pkcs11.so
RUN mv /aws_kms_pkcs11.so "/usr/lib/$(uname -m)-linux-gnu/pkcs11/aws_kms_pkcs11.so"
COPY builder /builder
RUN mkdir /builder/cert
COPY setup_namespace /usr/sbin/setup_namespace
RUN echo 'root:1:65535' | tee /etc/subuid /etc/subgid > /dev/null
ENTRYPOINT [ "/usr/sbin/setup_namespace" ]
