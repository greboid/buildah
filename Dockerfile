FROM ubuntu:22.04

ENV PATH=$PATH:/usr/local/go/bin

RUN set -eux; \
apt-get -y -qq update; \
apt-get -y -qq dist-upgrade; \
apt-get -y install \
	build-essential \
	make \
	git \
	curl \
	bats \
	btrfs-progs \
	golang-github-cpuguy83-go-md2man-v2-dev \
	libapparmor-dev \
	libglib2.0-dev \
	libgpgme11-dev \
	libseccomp-dev \
	libselinux1-dev \
	skopeo

RUN set -eux; \
echo "[advice]" > /etc/gitconfig; \
echo "    detachedHead = false" >> /etc/gitconfig;

RUN set -eux; \
curl -Ss -L -o /go.tgz https://go.dev/dl/go1.22.2.linux-amd64.tar.gz; \
rm -rf /usr/local/go; \
tar -C /usr/local -xzf go.tgz; \
rm -r /go.tgz

RUN set -eux; \
git clone --depth=1 -b v1.35.3 https://github.com/containers/buildah; \
cd /buildah

ENV DESTDIR=/debpackage

RUN set -eux; \
cd /buildah; \
mkdir /debpackage; \
make runc all SECURITYTAGS="apparmor seccomp"; \
make install

RUN set -eux; \
mkdir $DESTDIR/DEBIAN /output; \
echo "Package: buildah" > $DESTDIR/DEBIAN/control; \
echo "Version: 1.35.3-1+greboid" >> $DESTDIR/DEBIAN/control; \
echo "Section: base" >> $DESTDIR/DEBIAN/control; \
echo "Priority: optional" >> $DESTDIR/DEBIAN/control; \
echo "Architecture: amd64" >> $DESTDIR/DEBIAN/control; \
echo "Maintainer: Greg Holmes<git@greg.holmes.name>" >> $DESTDIR/DEBIAN/control; \
echo "Description: Buildah - https://github.com/containers/buildah - Quick install for github runners" >> $DESTDIR/DEBIAN/control; \
dpkg-deb --build $DESTDIR /output/buildah-1.35.3-1+greboid.deb

RUN set -eux; \
dpkg -i /output/buildah-1.35.3-1+greboid.deb
