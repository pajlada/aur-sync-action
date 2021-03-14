#!/bin/bash

set -o errexit -o pipefail -o nounset

PACKAGE_NAME=$INPUT_PACKAGE_NAME
COMMIT_USERNAME=$INPUT_COMMIT_USERNAME
COMMIT_EMAIL=$INPUT_COMMIT_EMAIL
SSH_PRIVATE_KEY=$INPUT_SSH_PRIVATE_KEY
DRY_RUN=$INPUT_DRY_RUN

echo "Dry run: '$DRY_RUN'"

HOME=/home/builder

# config ssh 
ssh-keyscan -t ed25519 aur.archlinux.org >> $HOME/.ssh/known_hosts
echo -e "${SSH_PRIVATE_KEY//_/\\n}" > $HOME/.ssh/aur
chmod 600 $HOME/.ssh/aur*

# config git
git config --global user.name "$COMMIT_USERNAME"
git config --global user.email "$COMMIT_EMAIL"
AUR_REPO_URL="ssh://aur@aur.archlinux.org/${PACKAGE_NAME}.git"

echo "---------------- CLONE REPO ----------------"
cd /tmp
git clone "$AUR_REPO_URL"
cd "$PACKAGE_NAME"

echo "------------- DIFF VERSION ----------------"

CURRENT_VER=$(grep pkgver .SRCINFO | awk -F '=' '{print $2}' | tr -d "[:space:]")

echo "old version is $CURRENT_VER"

echo "------------- BUILDING PKG $PACKAGE_NAME ----------------"

if [ -n "$INPUT_EXTRA_DEPENDENCIES" ]; then
  echo "------------- EXTRA DENPENDENCIES ----------------"
  sudo pacman -Sy --noconfirm "$INPUT_EXTRA_DEPENDENCIES"
fi

echo "------------- MAKE PACKAGE ----------------"
# test build
makepkg -s --noconfirm
# update srcinfo
makepkg --printsrcinfo > .SRCINFO

echo "------------- BUILD DONE ----------------"

# update aur
echo "Running git diff"
git diff
echo "running git diff in the if"
if ! git diff --exit-code; then
    echo "there was a diff!!!!"
    NEW_PKGVER=$(grep pkgver .SRCINFO | awk -F '=' '{print $2}' | tr -d "[:space:]")
    echo "new version is $NEW_PKGVER"
    # Changes have been made, add and push
    git add PKGBUILD .SRCINFO
    git commit -m "Update to $NEW_PKGVER"
    if [ "$DRY_RUN" = "true" ]; then
        echo "dry run"
        git --no-pager log -p
    else
        echo "pushing"
        git push
    fi
else
    echo "Nothing changed, looks like we're up to date!"
fi

echo "------------- SYNC DONE ----------------"
