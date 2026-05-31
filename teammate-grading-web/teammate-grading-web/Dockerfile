FROM eclipse-temurin:17-jdk AS builder

WORKDIR /app

COPY gradle gradle
COPY gradlew settings.gradle build.gradle ./
RUN chmod +x gradlew

COPY src src
RUN ./gradlew bootJar --no-daemon

FROM eclipse-temurin:17-jre

WORKDIR /app

COPY --from=builder /app/build/libs/*.jar app.jar

EXPOSE 8889

ENTRYPOINT ["java", "-jar", "app.jar"]
