platform "el-6-ppc64" do |plat|
  plat.servicedir "/etc/rc.d/init.d"
  plat.defaultdir "/etc/sysconfig"
  plat.servicetype "sysv"
  plat.num_cores "echo 0" # haxors

  plat.provision_with "yum install --assumeyes autoconf automake createrepo rsync gcc make rpmdevtools rpm-libs yum-utils rpm-sign;"
  plat.install_build_dependencies_with "yum install --assumeyes"
end
