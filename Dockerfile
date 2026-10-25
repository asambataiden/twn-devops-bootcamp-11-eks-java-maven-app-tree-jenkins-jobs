FROM amazoncorretto:17-alpine-jre
WORKDIR /app
COPY target/java-maven-app-*.jar /app/app.jar
EXPOSE 8080
USER 10001:10001
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
