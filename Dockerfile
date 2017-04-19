# Base build on latest release of the official Oracle JDK
FROM airdock/oracle-jdk:jdk-8u112
MAINTAINER Gary Rowe <gary.rowe@bitcoin-solutions.co.uk>

# Reference the home directory
ENV HOME=/home/java

# Add the local Java distribution to the build
ADD ./build/libs/example-service-0.1-all.jar $HOME/app/example-service-0.1-all.jar
ADD ./lib/quasar-0.7.6-dev.jar $HOME/app/quasar-0.7.6-dev.jar

# Ensure the java user has permissions
RUN chown -R java:java $HOME/*

# Switch to java user for reduced privileges
USER java

# Move to root of application
WORKDIR $HOME/app

# Provide a default external command to run in the WORKDIR
# A Corda node should run in 200Mb of memory as of Corda-M8 but real world tests show more is needed
CMD java -Xmx512m -XX:OnOutOfMemoryError="kill -9 $PPID" \
-ea -javaagent:quasar-0.7.6-dev.jar \
-Dco.paralleluniverse.fibers.verifyInstrumentation=false \
-jar example-service-0.1-all.jar

# Dockerfile must expose the ports to allow Swarm to avoid conflicts
# Swarm will create suitable proxy redirects
EXPOSE 20000 20001 20002 20003