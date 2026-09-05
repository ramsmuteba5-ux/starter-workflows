#!/bin/bash
# run-git.sh
# Script d'aide pour les opérations Git de base (français)
# Usage:
#   1) Adaptez les variables REPO, BRANCH, NAME et EMAIL si nécessaire.
#   2) Rendez le script exécutable: chmod +x scripts/run-git.sh
#   3) Lancez-le: ./scripts/run-git.sh

set -euo pipefail
IFS=$'\n\t'

# --- CONFIGUREZ CE QUI SUIT SI NÉCESSAIRE ---
REPO_DEFAULT="https://github.com/ramsmuteba5-ux/starter-workflows.git"
BRANCH_DEFAULT="feature/ma-fonctionnalite"
NAME_DEFAULT="Votre Nom"
EMAIL_DEFAULT="vous@example.com"

# Vous pouvez remplacer les valeurs ci‑dessous en exportant des variables d'environnement
# avant d'exécuter le script, par exemple:
# REPO="..." BRANCH="..." NAME="..." EMAIL="..." ./scripts/run-git.sh

REPO="${REPO:-$REPO_DEFAULT}"
BRANCH="${BRANCH:-$BRANCH_DEFAULT}"
NAME="${NAME:-$NAME_DEFAULT}"
EMAIL="${EMAIL:-$EMAIL_DEFAULT}"

echo "Script d'assistance Git - actions qui seront effectuées :"
echo "- Cloner : $REPO"
echo "- Créer / basculer sur la branche : $BRANCH"
echo "- Créer un fichier docs/notes.txt de test"
echo "- Ajouter, commit, tenter de se synchroniser avec la branche principale distante, puis push"

echo
read -p "Continuer ? (o/N) : " -r
if [[ ! $REPLY =~ ^([oO]|oui|Oui)$ ]]; then
  echo "Annulation par l'utilisateur."
  exit 1
fi

# Vérifier que git est installé
if ! command -v git >/dev/null 2>&1; then
  echo "git n'est pas installé. Installez git puis réessayez." >&2
  exit 2
fi

# Cloner le dépôt
REPO_DIR=$(basename "$REPO" .git)
if [[ -d "$REPO_DIR" ]]; then
  echo "Le dossier $REPO_DIR existe déjà. Je vais l'utiliser." 
  cd "$REPO_DIR"
else
  git clone "$REPO"
  cd "$REPO_DIR"
fi

# Configurer user.name/user.email localement (ne change pas la config globale)
git config user.name "$NAME" || true
git config user.email "$EMAIL" || true

# Créer et basculer sur la branche de travail
if git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  git checkout "$BRANCH"
else
  git checkout -b "$BRANCH"
fi

# Créer un fichier de test
mkdir -p docs
echo "Notes générées le $(date -R)" > docs/notes.txt

# Vérifier l'état avant staging
echo
echo "=== git status ==="
git status --short --branch || true

# Ajouter et committer
git add docs/notes.txt
git commit -m "Ajout: notes de test via run-git.sh" || echo "Aucun changement à committer."

# Tenter de récupérer la branche principale distante (essayer main puis master)
set +e
echo
echo "Tentative de synchronisation avec la branche principale distante..."
if git fetch origin main >/dev/null 2>&1; then
  MAIN_REMOTE=main
elif git fetch origin master >/dev/null 2>&1; then
  MAIN_REMOTE=master
else
  MAIN_REMOTE=""
fi
set -e

if [[ -n "$MAIN_REMOTE" ]]; then
  echo "Branche principale distante détectée : $MAIN_REMOTE. Rebasage local sur origin/$MAIN_REMOTE (si possible)."
  git pull --rebase origin "$MAIN_REMOTE" || echo "Échec du rebase automatique — résolvez les conflits localement si nécessaire."
else
  echo "Impossible de détecter 'main' ou 'master' sur le remote, saut de la synchronisation automatique."
fi

# Push de la branche de travail (définir upstream si nécessaire)
if git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  echo "Upstream déjà défini, push standard."
  git push
else
  echo "Push initial de la branche et définition de l'upstream vers origin/$BRANCH"
  git push -u origin "$BRANCH"
fi

echo
echo "Terminé. Quelques commandes utiles :"
echo "  git status"
echo "  git log --oneline --graph --decorate"
echo "  git diff (voir les différences non indexées)"
echo "Si vous voulez annuler le fichier de test : git rm docs/notes.txt && git commit -m 'Supprime notes de test' && git push"
