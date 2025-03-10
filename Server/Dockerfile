# # Build stage
# FROM maven:3-openjdk-17 AS build
# WORKDIR /app
# COPY . .
# RUN mvn clean package -DskipTests

# # Run stage
# FROM openjdk:17-jdk-slim
# WORKDIR /app
# COPY --from=build /app/target/DrComputer-0.0.1-SNAPSHOT.war drcomputer.war
# EXPOSE 8080
# ENTRYPOINT ["java", "-jar", "drcomputer.war"]


FROM maven:3-eclipse-temurin-17 AS build
COPY . .
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-alpine
WORKDIR /app # Đặt thư mục hiện tại thành /app
COPY --from=build /target/*.jar /target/demo.jar 
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/target/demo.jar"]
