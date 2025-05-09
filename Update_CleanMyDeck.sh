#!/bin/bash

REPO_URL="https://github.com/ruifcastro/CleanMyDeck.git"
TARGET_DIR="$HOME/CleanMyDeck"

if [ ! -d "$TARGET_DIR/.git" ]; then
  rm -rf "$TARGET_DIR"
  git clone "$REPO_URL" "$TARGET_DIR"
else
  cd "$TARGET_DIR" && git pull
fi
