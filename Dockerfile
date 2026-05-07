# Stage 1: Build (Using Alpine for the builder too)
FROM maven:3.9.4-eclipse-temurin-17-alpine AS builder
WORKDIR /app

# Copy only pom.xml to cache dependencies
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source and build
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run (The tiny part)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Create a dedicated system user for security
RUN addgroup -S spring && adduser -S spring -G spring

# Copy the jar from the builder stage
COPY --from=builder /app/target/bankapp-0.0.1-SNAPSHOT.jar app.jar

# Tell Docker to run as the 'spring' user instead of root
USER spring

EXPOSE 8080

# Tune Java for Containers (Prevents 'Out of Memory' crashes in K8s)
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]
