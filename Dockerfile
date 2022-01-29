#FROM nubificus/jetson-inference:aarch64
FROM dustynv/jetson-inference:r32.6.1

# Install common build utilities
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -yy eatmydata && \
	DEBIAN_FRONTEND=noninteractive eatmydata \
	apt-get install -y --no-install-recommends \
		openssh-server \
		ca-certificates \
		git \
		sudo \
		libpython3-dev \
		python3-numpy \
	&& rm -rf /var/lib/apt/lists/*

# we need this for installing download-models.sh and base network models.
RUN cd /jetson-inference && \
	git clone https://github.com/dusty-nv/jetson-inference --depth 1
#
#RUN cd /jetson-inference/jetson-inference && git submodule update --init && \
#	mkdir build && cd build && cmake .. && \
#	make -j$(nproc) && make install && ldconfig

RUN cd /jetson-inference && \
	cp -a utils/image/stb /usr/local/include && \
	mkdir /usr/local/share/jetson-inference/tools && \
	cp tools/download-models.sh /usr/local/share/jetson-inference/tools/ && \
	mkdir /usr/local/share/jetson-inference/data && \
	cp -r jetson-inference/data/networks /usr/local/share/jetson-inference/data/ && \
	sed 's/BUILD_INTERACTIVE=.*/BUILD_INTERACTIVE=0/g' \
		-i /usr/local/share/jetson-inference/tools/download-models.sh && \
	unlink /usr/local/bin/images && unlink /usr/local/bin/networks && \
	ln -s /usr/local/share/jetson-inference/data/networks /usr/local/bin/

RUN rm -rf /jetson-inference

WORKDIR /

#FROM nubificus/jetson-inference:aarch64

# Install common build utilities
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -yy eatmydata && \
	DEBIAN_FRONTEND=noninteractive eatmydata \
	apt-get install -y --no-install-recommends \
		bison \
		flex \
		build-essential \
		libglib2.0-dev \
		libfdt-dev \
		libpixman-1-dev \
		zlib1g-dev \
		pkg-config \
		iproute2 \
		libcap-ng-dev \
		libattr1-dev \
		$(apt-get -s build-dep qemu | egrep ^Inst | fgrep '[all]' | cut -d\  -f2) \
	&& rm -rf /var/lib/apt/lists/*

ARG TOKEN
# Build & install vaccelrt
RUN git clone https://${TOKEN}:x-oauth-basic@github.com/nubificus/vaccelrt-plugin-jetson vaccelrt && \
	cd vaccelrt && git submodule update --init && \
	cd vaccelrt && git submodule update --init && \
	mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_EXAMPLES=ON .. && \
	make install && cd ../.. && mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && make install && \
	cd ../.. && rm -rf vaccelrt && \
	echo "/usr/local/lib" >> /etc/ld.so.conf.d/vaccel.conf && \
	echo "/sbin/ldconfig" >> /root/.bashrc && \
	mkdir /run/user

# Build & install QEMU w/ vAccel backend
RUN git clone https://${TOKEN}:x-oauth-basic@github.com/cloudkernels/qemu-vaccel.git \
	-b vaccelrt --depth 1 && cd qemu-vaccel && \
	git submodule update --init && \
	./configure --target-list=aarch64-softmmu --enable-virtfs && \
	make -j$(nproc) && make install && \
	cd .. && rm -rf qemu-vaccel

COPY qemu-ifup /etc/qemu-ifup
COPY qemu-script.sh /run.sh

VOLUME /data
WORKDIR /data
ENTRYPOINT ["/run.sh"]
