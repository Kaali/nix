dry-check:
	darwin-rebuild check --dry-run

check:
	darwin-rebuild check

build:
	darwin-rebuild build

switch:
	darwin-rebuild switch -Q

pull:
	(cd darwin && git pull --rebase)
	(cd nixpkgs && git pull --rebase)

update: pull check switch

commit:
	git add -u && git commit -m "Update"
