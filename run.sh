#!/bin/bash
java -XX:MaxRAMPercentage=75 -Dderby.stream.error.file=/app/data/derby.log -cp "/app/lib/*" org.openlca.ipc.Server -timeout 30 -native /app/native -data /app/data "$@"
