# Copyright (c) 2015-2017 Eric Vidal <eric@obarun.org>
# All rights reserved.
# 
# This file is part of Obarun. It is subject to the license terms in
# the LICENSE file found in the top-level directory of this
# distribution and at https://github.com/Obarun/obarun-build/LICENSE
# This file may not be copied, modified, propagated, or distributed
# except according to the terms contained in the LICENSE file.
#
# Maintainer: Obarun-build scripts <eric@obarun.org>
# DO NOT EDIT this PKGBUILD if you don't know what you do

pkgname=obarun-build
pkgver=23536df
pkgrel=1
pkgdesc=" Script for building package on clean environment with lxc container"
arch=(x86_64)
url="file:///var/lib/obarun/$pkgname/update_package/$pkgname"
license=(ISC)
depends=('git' 'pacman' 'obarun-libs' 'lxc')
backup=('etc/obarun/build.conf')
install=
source=("$pkgname::git+file:///var/lib/obarun/$pkgname/update_package/$pkgname")
md5sums=('SKIP')
validpgpkeys=('6DD4217456569BA711566AC7F06E8FDE7B45DAAC') # Eric Vidal

pkgver() {
	cd "${pkgname}"
	
	git describe --tags | sed -e 's:-:+:g;s:^v::'
}

package() {
	cd "${pkgname}"

	make DESTDIR="$pkgdir" install
}

