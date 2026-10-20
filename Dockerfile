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
FROM ${BASE_IMAGE}
COPY --from=mvn /olca-ipc/target/lib /app/lib
COPY --from=native /app/native /app/native
# heap sized from the container memory limit instead of a fixed -Xmx;
# derby.log goes to the (writable) data volume instead of the working directory
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-Dderby.stream.error.file=/app/data/derby.log", "-cp", "/app/lib/*", "org.openlca.ipc.Server", "-timeout", "30", "-native", "/app/native", "-data", "/app/data"]
