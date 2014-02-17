## "What can the harvest hope for, if not for the care of the Reaper Man?"

Grow code, harvest packages

### Harvests

Package repository is maintained via `JSON` file. Packages are added or removed
from the `JSON` registry. Repository generation will result in skeleton repository
with the proper `Release` and `Packages` files. Package paths will be not exist
within the generated repository. Resolving that issue is left to the reader.


### Support

* Currently: `deb/apt`
* In progress: `rpm/yum`

### Usage

#### Add package to registry

```
> reaper package add my_pkg.deb --packages-file registry.json
```

### Remove package from registry

```
> reaper package remove my_pkg --packages-file registry.json
```

or remove a specific version

```
> reaper package remove my_pkg 1.0.0 --packages-file registry.json
```

### Create a repository

```
> reaper repo create --packages-file registry.json --package-system apt --output-directory /tmp/test-repo
```

This can also be used to update an existing repository structure.

## Infos
* Repository: https://github.com/heavywater/reaper
* IRC: Freenode @ #heavywater
