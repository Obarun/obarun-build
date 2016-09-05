# Maintainer: Obarun-build scripts <eric@obarun.org>
# DO NOT EDIT this PKGBUILD if you don't know what you do

pkgname=obarun-build
pkgver=23536df
pkgrel=1
pkgdesc=" Script for build package on a lxc container"
arch=(x86_64)
url="file:///var/lib/obarun/$pkgname/update_package/$pkgname"
license=('BEERWARE')
depends=('git' 'pacman' 'obarun-libs' 'lxc')
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
	install -Dm 0755 "build_functions" "$pkgdir/usr/lib/obarun/build_functions"
	install -Dm 0644 "build.conf" "$pkgdir/etc/obarun/build.conf"
	install -dm 0755 "$pkgdir/usr/share/obarun/obarun-build/templates"
	for file in templates/{cont_create.conf,cont_pkg_base,cont_start.conf,makepkg,pacman.conf}; do
		install -Dm 0644 "${file}" "$pkgdir/usr/shar/obarun/obarun-build/templates"
	done
	for file in templates/{cont_create,cont_customize}; do
		install -Dm 0755 "${file}" "$pkgdir/usr/share/obarun/obarun-build/templates"
	done
	install -dm 0755 "$pkgdir/usr/share/licenses/obarun-build/"
	install -Dm 0644 "LICENSE" "$pkgdir/usr/share/licenses/obarun-build/LICENSE"
	#install -Dm 0644 "PKGBUILD" "$pkgdir/var/lib/obarun/obarun-build/update_package/PKGBUILD"
}

