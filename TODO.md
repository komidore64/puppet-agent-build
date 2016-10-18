# TODO

## srpm_foundry

- keep track of each machine's returned ssh-keyscans. some of them don't contain the hostname, so they all don't get deleted when cleaning up.
- possible refactor the passed around array of boxes (which are also just arrays) into an array of box objects. that seems less cryptic.
