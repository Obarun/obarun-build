# Maintainer: Obarun-build scripts <eric@obarun.org>
# DO NOT EDIT this PKGBUILD if you don't know what you do

pkgname=obarun-build
pkgver=23536df
pkgrel=1
pkgdesc=" Script for building package on clean environment with lxc container"
arch=(x86_64)
url="file:///var/lib/obarun/$pkgname/update_package/$pkgname"
license=('BEERWARE')
depends=('git' 'pacman' 'obarun-libs' 'lxc=>2.1.0')
backup=('etc/obarun/build.conf')
install=
source=("$pkgname::git+file:///var/lib/obarun/$pkgname/update_package/$pkgname")
md5sums=('SKIP')
validpgpkeys=('6DD4217456569BA711566AC7F06E8FDE7B45DAAC') # Eric Vidal

pkgver() {
	cd "${pkgname}"
	if git_version=$(git rev-parse --short HEAD); then
		read "$rev-parse" <<< "$git_version"
		printf '%s' "$git_version"
	fi
}


package() {
	cd "$srcdir/$pkgname"
	
	install -Dm 0755 "obarun-build.in" "$pkgdir/usr/bin/obarun-build"
	install -Dm 0755 "build.sh" "$pkgdir/usr/lib/obarun/build.sh"
	install -Dm 0644 "build.conf" "$pkgdir/etc/obarun/build.conf"
	
	install -dm 0755 "$pkgdir/usr/lib/obarun/build/"
	for file in build/{manage.sh,network.sh,util.sh};do
		install -Dm 0755 "${file}" "$pkgdir/usr/lib/obarun/build/"
	done
	
	install -dm 0755 "$pkgdir/usr/share/obarun/obarun-build/templates"
	for file in templates/{create.conf,pkglist_*,start.conf,makepkg.conf,pacman.conf}; do
		install -Dm 0644 "${file}" "$pkgdir/usr/share/obarun/obarun-build/templates"
	done
	
	install -Dm 0755 "templates/create" "$pkgdir/usr/share/obarun/obarun-build/templates"
	
	install -dm 0755 "$pkgdir/usr/share/licenses/obarun-build/"
	install -Dm 0644 "LICENSE" "$pkgdir/usr/share/licenses/obarun-build/LICENSE"
	#install -Dm 0644 "PKGBUILD" "$pkgdir/var/lib/obarun/obarun-build/update_package/PKGBUILD"
}

