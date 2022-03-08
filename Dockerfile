FROM nubificus/jetson-inference:aarch64

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
		cargo \
		libclang-dev \
		clang \
	&& rm -rf /var/lib/apt/lists/*

ARG TOKEN
# Build & install vaccelrt
RUN git clone -b update_image_ops \
	https://${TOKEN}:x-oauth-basic@github.com/nubificus/vaccelrt-plugin-jetson && \
	cd vaccelrt-plugin-jetson && git submodule update --init && \
	cd vaccelrt && git submodule update --init && \
	mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_EXAMPLES=ON .. && \
	make install && cd ../.. && mkdir build && cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && make install && \
	cd ../.. && rm -rf vaccelrt-plugin-jetson && \
	echo "/usr/local/lib" >> /etc/ld.so.conf.d/vaccel.conf && \
	echo "/sbin/ldconfig" >> /root/.bashrc && \
	mkdir /run/user

# Build & install QEMU w/ vAccel backend
RUN git clone -b vaccelrt --depth 1 \
	https://${TOKEN}:x-oauth-basic@github.com/cloudkernels/qemu-vaccel.git && \
	cd qemu-vaccel && git submodule update --init && \
	./configure --target-list=aarch64-softmmu --enable-virtfs && \
	make -j$(nproc) && make install && \
	cd .. && rm -rf qemu-vaccel

# Build & install vaccelrt agent
RUN git clone -b feat_genop \
	https://${TOKEN}:x-oauth-basic@github.com/cloudkernels/vaccelrt-agent && \
	cd vaccelrt-agent && \
	cargo build && \
	cp $(find -name "vaccelrt-agent") /usr/local/bin/ && \
	cd .. && rm -rf vaccelrt-agent

COPY qemu-ifup /etc/qemu-ifup
COPY qemu-script.sh /run.sh

VOLUME /data
WORKDIR /data
ENTRYPOINT ["/run.sh"]
