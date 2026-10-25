FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

COPY --chown=10001:10001 target/java-maven-app-*.jar /app/app.jar

USER 10001:10001

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
