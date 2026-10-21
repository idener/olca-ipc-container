ARG BUILD_IMAGE=maven:3.9-eclipse-temurin-21
ARG BASE_IMAGE=eclipse-temurin:21-jre

# collect Maven dependencies
FROM ${BUILD_IMAGE} AS mvn
WORKDIR /olca-ipc
COPY pom.xml .
RUN mvn package

# native libraries (pinned: the image only publishes a moving `latest` tag)
FROM ghcr.io/greendelta/gdt-server-native@sha256:4a5b20ea330bbbf1889839822214db38a93b8305e5c445a777067a34f531617e AS native

# final image
FROM ${BUILD_IMAGE} AS ca-fix
USER root
# Distrust the roots behind the compromised eMudhra intermediates (CVE-2026-111943)
RUN if [ -f /etc/ca-certificates.conf ]; then \
      { apt-get update && apt-get install -y --no-install-recommends --only-upgrade ca-certificates; } || true; \
      sed -i -e 's|^mozilla/emSign_ECC_Root_CA_-_G3.crt|!&|' -e 's|^mozilla/Comodo_AAA_Services_root.crt|!&|' /etc/ca-certificates.conf \
      && update-ca-certificates; \
    fi; rm -rf /var/lib/apt/lists/*
# Remove the eMudhra ECC G3 root from the JDK trust store (CVE-2026-111943)
RUN keytool -delete -cacerts -storepass changeit \
      -alias "cn_emsign_ecc_root_ca__g3,o_emudhra_technologies_limited,ou_emsign_pki,c_in [jdk]" \
 && cp "$(readlink -f "$JAVA_HOME/lib/security/cacerts")" /tmp/cacerts

FROM ${BASE_IMAGE}
COPY --from=ca-fix /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=ca-fix /tmp/cacerts ${JAVA_HOME}/lib/security/cacerts
COPY --from=mvn /olca-ipc/target/lib /app/lib
COPY --from=native /app/native /app/native
# heap sized from the container memory limit instead of a fixed -Xmx;
# derby.log goes to the (writable) data volume instead of the working directory
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-Dderby.stream.error.file=/app/data/derby.log", "-cp", "/app/lib/*", "org.openlca.ipc.Server", "-timeout", "30", "-native", "/app/native", "-data", "/app/data"]
