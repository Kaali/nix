.PHONY: dry-check
dry-check:
	darwin-rebuild check --dry-run

.PHONY: check
check:
	darwin-rebuild check

.PHONY: working
working:
	(cd nixpkgs && git branch -f working HEAD)
	(cd darwin && git branch -f working HEAD)

.PHONY: build
build:
	darwin-rebuild build

.PHONY: switch
switch:
	darwin-rebuild switch -Q

.PHONY: pull
pull:
	(cd darwin && git pull --rebase)
	(cd nixpkgs && git pull --rebase)

.PHONY: update
update: pull check switch

.PHONY: commit
commit:
	git add -u && git commit -m "Update"
