ARG BUILD_IMAGE=maven:3.9.3-eclipse-temurin-17
ARG BASE_IMAGE=eclipse-temurin:17-jre

# collect Maven dependencies
FROM ${BUILD_IMAGE} AS mvn
WORKDIR /olca-ipc
COPY pom.xml .
RUN mvn package

# native libraries
FROM ghcr.io/greendelta/gdt-server-native AS native

# final image
FROM ${BASE_IMAGE}
COPY --from=mvn /olca-ipc/target/lib /app/lib
COPY --from=native /app/native /app/native
COPY --chmod=0755 run.sh /app
ENTRYPOINT ["/app/run.sh"]
