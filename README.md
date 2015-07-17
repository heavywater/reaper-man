## Reaper Man
#### "What can the harvest hope for, if not for the care of the Reaper Man?"
##### - Terry Pratchett

Grow code, harvest packages

### Harvests

Reaper man generates a `JSON` registry that describes one or more package repositories
that can be used to generate the expected repository file system. Packages are added
or removed from the registry, and regeneration of the repository file system is fast
and simple. The generated repository file system will refer to the referenced packages
but will not actually contain the referenced packages. Storage of the actual package
assets (and the delivery of said assets) is left to the reader.

### Support

#### Enabled

* deb/apt
* gem/rubygems

#### In Progress

* rpm/yum

### Usage

#### Add package to registry

```
> reaper-man package add my_pkg.deb --packages-file registry.json
```

### Remove package from registry

```
> reaper-man package remove my_pkg --packages-file registry.json
```

or remove a specific version

```
> reaper-man package remove my_pkg 1.0.0 --packages-file registry.json
```

### Create a repository

```
> reaper-man repo create --packages-file registry.json --package-system apt --output-directory /tmp/test-repo
```

This can also be used to update an existing repository structure.

### Dependencies

Commands that must be available within the path:

* `gpg`
* `debsigs`
* `expect`

## Infos
* Repository: https://github.com/hw-labs/reaper-man
* IRC: Freenode @ #heavywater
