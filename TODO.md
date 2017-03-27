# TODO

## srpm_foundry

- Keep track of each machine's returned ssh-keyscans. Some of them don't contain the hostname, so they all don't get deleted when cleaning up.
- Possibly refactor the passed around array of boxes (which are also just arrays) into an array of box objects. That seems less cryptic. Also better design.
- Provide mechanism for the foundry to pick where it left off if there was an interuption. This will allow for closing of the pry session without losing references to the objects.

## general building/testing notes

there are four distro/arch combinations that we need built and tested

- el6 s390x
- el6 ppc64
- el7 s390x
- el7 ppc64

i've smoke tested and confirmed el7-s390x using `puppet -V` and `puppet module install puppetlabs-motd`.

to build the RPM using the SRPM that puppet-agent-build gives us back, i used something like `koji build --scratch --arch-override=ppc64 build-target /path/to/puppet-agent-1.8.2-1.el6.src.rpm`.

el6-s390x is currently yelling about missing libfacter. need to figure that out.

puppet module install on el7-ppc64 segfaults.
