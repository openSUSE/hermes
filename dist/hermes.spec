#
# spec file for package obs-server
#
# Copyright (c) 2008 SUSE LINUX Products GmbH, Nuernberg, Germany.
# This file and all modifications and additions to the pristine
# package are under the same license as the package itself.
#
# Please submit bugfixes or comments via http://bugs.opensuse.org/
#



Name:           hermes
Summary:        Server component

Version:        0.7
Release:        0
License:        GPL
Group:          Productivity/Networking/Web/Utilities
Url:            http://en.opensuse.org/openSUSE:Hermes
BuildRoot:      /var/tmp/%name-root

Source:         hermes-%{version}.tar.bz2
Source1:        sysconfig.hermes
Source2:        hermesserver
Source3:        starship.conf
Source4:        herminator.conf

Autoreqprov:    on

BuildRequires:  lighttpd

%package herminator
Requires:       perl-CGI-Application perl-HTML-Template 
Requires:       lighttpd mysql
Requires:       hermes

Summary:the admin web interface

%description -n hermes-herminator

  this is the herminator


Group:          Productivity/Networking/Web/Utilities


%package starship
Requires:       lighttpd ruby-fcgi mysql ruby-mysql
# make sure this is in sync with the RAILS_GEM_VERSION specified in the
# config/environment.rb of the various applications.
Requires:       rubygem-rails-2_3 = 2.3.5

Summary:        the user web interface

%package obs
Requires:       hermes hermes-starship hermes-herminator

Summary:        openSUSE Buildservice relevant database

%description 
Authors:
--------
  The openSUSE Hermes 

%description -n hermes-starship
the user web application

%description -n hermes-obs
data needed for the openSUSE Buildservice

# ================================================================

%prep

%setup
# remove all links out of the tarball
find . -type l -exec rm {} \;
find . -name .gitignore -exec rm {} \;
find . -name Capfile -exec rm {} \;
rm -rf starship/nbproject

%build

%install

# install the binaries
BIN_DIR=$RPM_BUILD_ROOT/%{_bindir}
mkdir -p $BIN_DIR
install -m 775 hermesworker.pl $BIN_DIR
install -m 775 hermesgenerator.pl $BIN_DIR
install -m 775 notifyHermes.pl $BIN_DIR

# Install the perl libs
PERL_LIB_DIR=$RPM_BUILD_ROOT/%{perl_vendorlib}/Hermes

mkdir -p $PERL_LIB_DIR

install -d -m 755 $PERL_LIB_DIR
install -d -m 755 $PERL_LIB_DIR/Delivery

install -m 0644 Hermes/*.pm $PERL_LIB_DIR
install -m 0644 Hermes/Delivery/*pm $PERL_LIB_DIR/Delivery

HERMES_VAR_DIR=$RPM_BUILD_ROOT/var/lib/hermes/
mkdir -p $HERMES_VAR_DIR
mv herminator/notifications $HERMES_VAR_DIR

# Guiabstractions read by the starship startup code
mv starship/config/guiabstractions $HERMES_VAR_DIR

HERMES_DIR=$RPM_BUILD_ROOT/srv/www/hermes
mkdir -p $HERMES_DIR
cp -r herminator $HERMES_DIR

cp -r starship $HERMES_DIR
rm $HERMES_DIR/starship/README.rails

# Fillup 
FILLUP_DIR=$RPM_BUILD_ROOT/var/adm/fillup-templates
install -d -m 755 $FILLUP_DIR
install -m 0644 %{SOURCE1} $FILLUP_DIR/

# Startscript
install -d -m 755 $RPM_BUILD_ROOT/etc/init.d/
install -d -m 755 $RPM_BUILD_ROOT/usr/sbin/
install -m 0755 %{SOURCE2} $RPM_BUILD_ROOT/etc/init.d/hermes
ln -sf /etc/init.d/hermes $RPM_BUILD_ROOT/usr/sbin/rchermes

# lighty-config
LIGTHY_DIR=$RPM_BUILD_ROOT/etc/lighttpd15/conf.d/
install -d -m 775 $LIGTHY_DIR
install -m 0755 %{SOURCE3} $LIGTHY_DIR
install -m 0755 %{SOURCE4} $LIGTHY_DIR

%post -n hermes
%{fillup_and_insserv -n hermes}

%postun
%insserv_cleanup

%files -n hermes-herminator
%defattr(-,root,root)
/srv/www/hermes/herminator
%dir /etc/lighttpd15/
%dir /etc/lighttpd15/conf.d/
/etc/lighttpd15/conf.d/herminator.conf

%files -n hermes-starship
%defattr(-,lighttpd,lighttpd)
%dir /var/lib/hermes

%defattr(-,root,root)

%doc starship/README.rails
%dir /srv/www/hermes/starship
%dir /srv/www/hermes/starship/config
%dir /srv/www/hermes/starship/config/initializers
%dir /srv/www/hermes/starship/config/environments

%dir /etc/lighttpd15/
%dir /etc/lighttpd15/conf.d/
/etc/lighttpd15/conf.d/starship.conf
# /etc/init.d/obsapidelayed
# /etc/init.d/obswebuidelayed
# /etc/init.d/obsapisetup
# /usr/sbin/rcobsapisetup
# /usr/sbin/rcobsapidelayed
# /usr/sbin/rcobswebuidelayed
/srv/www/hermes/starship/app
/srv/www/hermes/starship/db
/srv/www/hermes/starship/doc
/srv/www/hermes/starship/lib
/srv/www/hermes/starship/public
/srv/www/hermes/starship/Rakefile
/srv/www/hermes/starship/script
/srv/www/hermes/starship/test
/srv/www/hermes/starship/vendor

# /var/adm/fillup-templates/sysconfig.obs-server

#
# some files below config actually are _not_ config files
# so here we go, file by file
#

/srv/www/hermes/starship/config/boot.rb
/srv/www/hermes/starship/config/routes.rb
/srv/www/hermes/starship/config/environments/development.rb
/srv/www/hermes/starship/config/database.example.yml
/srv/www/hermes/starship/config/database.yml
/srv/www/hermes/starship/config/deploy.rb
/srv/www/hermes/starship/config/starship.yml

/srv/www/hermes/starship/config/initializers/inflections.rb
/srv/www/hermes/starship/config/initializers/load_abstractions.rb
/srv/www/hermes/starship/config/initializers/load_config.rb
/srv/www/hermes/starship/config/initializers/mime_types.rb

%config /srv/www/hermes/starship/config/environment.rb
# %config(noreplace) /srv/www/hermes/starship/config/lighttpd.conf
%config(noreplace) /srv/www/hermes/starship/config/environments/production.rb
%config(noreplace) /srv/www/hermes/starship/config/environments/test.rb
# %config(noreplace) /etc/cron.d/obs-api

%dir %attr(-,lighttpd,lighttpd) /srv/www/hermes/
# %verify(not size md5) %attr(-,lighttpd,lighttpd) /srv/www/statship/production.log
%attr(-,lighttpd,lighttpd) /srv/www/hermes/starship/tmp

%files -n hermes-obs
%defattr(-,lighttpd,lighttpd)
/var/lib/hermes/*

%files
%defattr(-,root,root)

/usr/bin/hermesworker.pl
/usr/bin/hermesgenerator.pl
/usr/bin/notifyHermes.pl

/etc/init.d/hermes
/usr/sbin/rchermes

%doc README INSTALL

/var/adm/fillup-templates/sysconfig.hermes

%{perl_vendorlib}/Hermes


%changelog -n hermes
