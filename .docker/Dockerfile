from ubuntu:20.04

RUN apt-get update && \
	apt-get install -y software-properties-common sudo && \
	DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install -y build-essential && \
	add-apt-repository -y ppa:haxe/releases && \
	apt-get update && \
	apt-get install -y haxe && \
	groupadd -g 1000 builder && \
	useradd -g 1000 -u 1000 -m builder

RUN bash -c "echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers"

USER builder
RUN mkdir ~/haxelib && \
	haxelib setup ~/haxelib && \
	haxelib install lime && \
	haxelib install openfl && \
	haxelib install flixel && \
	haxelib run lime setup flixel && \
	yes | haxelib run lime setup && \
	haxelib install flixel-tools && \
	echo -e 'y\n4' | haxelib run flixel-tools setup

USER root
RUN sed -i 's/builder.*//g' /etc/sudoers && \
	cp /home/builder/haxelib/flixel-tools/1,5,1/bin/flixel.sh /usr/local/bin/flixel && \
	chmod 0755 /usr/local/bin/flixel

USER builder

USER root
RUN apt-get update && \
	apt-get install -y mingw-w64

USER builder
