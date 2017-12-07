# This image adds python3 to centos6
FROM centos:6

# install dependencies
RUN yum update && yum install -y gcc zlib-devel openssl-devel

# install python3
RUN mkdir /build && cd /build && \
	curl -O https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tgz && \
	tar xzf Python-3.5.2.tgz && cd Python-3.5.2 && \
	./configure && make && make install && \
	rm -rf /build

# get pip alongside pip3; is this better than a symlink?
RUN pip3 install --upgrade pip
