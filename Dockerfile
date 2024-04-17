FROM ubuntu:22.04

ENV PATH=$PATH:/usr/local/go/bin
ENV DESTDIR=/debpackage
ENV VER=1.35.3
ENV GOVER=1.22.2

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
curl -Ss -L -o /go.tgz https://go.dev/dl/go$GOVER.linux-amd64.tar.gz; \
rm -rf /usr/local/go; \
tar -C /usr/local -xzf go.tgz; \
rm -r /go.tgz

RUN set -eux; \
git clone --depth=1 -b v$VER https://github.com/containers/buildah; \
cd /buildah

RUN set -eux; \
cd /buildah; \
mkdir /debpackage; \
make runc all SECURITYTAGS="apparmor seccomp"; \
make install

RUN set -eux; \
DEBVER="$VER-1+greboid"; \
OUTFILE="/out/buildah-$DEBVER.deb"; \
mkdir $DESTDIR/DEBIAN /out; \
echo "Package: buildah" > $DESTDIR/DEBIAN/control; \
echo "Version: $DEBVER" >> $DESTDIR/DEBIAN/control; \
echo "Section: base" >> $DESTDIR/DEBIAN/control; \
echo "Priority: optional" >> $DESTDIR/DEBIAN/control; \
echo "Architecture: amd64" >> $DESTDIR/DEBIAN/control; \
echo "Maintainer: Greg Holmes<git@greg.holmes.name>" >> $DESTDIR/DEBIAN/control; \
echo "Description: Buildah - https://github.com/containers/buildah - Quick install for github runners" >> $DESTDIR/DEBIAN/control; \
dpkg-deb --build $DESTDIR "$OUTFILE"; \
echo "#!/bin/bash" >> /run.sh; \
echo "/usr/bin/gh release create v$VER --notes v$VER -t v$VER $OUTFILE --latest --repo greboid/buildah" >> /run.sh; \
chmod +x /run.sh

RUN set -eux; \
mkdir -p -m 755 /etc/apt/keyrings; \
curl -Ss -L -o /etc/apt/keyrings/githubcli-archive-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg; \
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg; \
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list; \
apt-get -y -qq update; \
apt-get -y -qq install gh

CMD ["/run.sh"]
