---
name: KCor release checklist
about: Checklist for a KCor pipeline release
title: 'Release KCor '
labels: release
assignees: mgalloy

---

### Pre-release check

- [ ] check to make sure no changes to the production config files are needed
- [ ] add date to version line in `RELEASES.md`
- [ ] check that version to release in `RELEASES.md` matches version in `CMakeLists.txt`

### Release to production

- [ ] merge master to production
- [ ] push production to origin
- [ ] tag production
- [ ] push tags

### Install production

- [ ] pull at `/hao/acos/sw/src/kcor-pipeline`
- [ ] run `production_configure.sh`
- [ ] `cd build; make`
- [ ] `make install` when the pipeline is not running

### Notify

- [ ] send email with new release notes to iguana, detoma, and observers

### Post-release check

- [ ] increment version in `CMakeLists.txt` and `RELEASES.md`

### Release to MLSO

A day after production release, release to MLSO.

- [ ] merge production to mlso
- [ ] push mlso to origin

### Install MLSO

A day after production release, release to MLSO.

- [ ] pull at `kodiak:~mgalloy/production-src/kcor-pipeline`
- [ ] run `mlso_configure.sh`
- [ ] `cd build; make`
- [ ] `make install` when the pipeline is not running
