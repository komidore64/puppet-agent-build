# TODO

## srpm_foundry

- Keep track of each machine's returned ssh-keyscans. Some of them don't contain the hostname, so they all don't get deleted when cleaning up.
- Possibly refactor the passed around array of boxes (which are also just arrays) into an array of box objects. That seems less cryptic. Also better design.
- Provide mechanism for the foundry to pick where it left off if there was an interuption. This will allow for closing of the pry session without losing references to the objects.
