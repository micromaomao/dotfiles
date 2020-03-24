FROM openjdk:11-jre-buster
RUN apt-get update -y && apt-get install -y git
RUN useradd -d /minecraft -m mc && \
		mkdir /minecraft/spigot/ && \
		chown mc:mc /minecraft/spigot
USER mc:mc
WORKDIR /minecraft/spigot/
RUN wget https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar && \
		java -jar BuildTools.jar --rev 1.15.2
COPY --chown=mc:mc spigot/ /minecraft/spigot
CMD [ "java", "-Xms256m", "-Xmx2048m", "-jar", "spigot-1.15.jar" ]
VOLUME [ "/minecraft/spigot/" ]
EXPOSE 25565
EXPOSE 25575
