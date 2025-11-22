# docker/php/Dockerfile
FROM composer:2 AS vendor

WORKDIR /app

# On copie uniquement ce qu'il faut pour installer les dépendances
COPY composer.json composer.lock* ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --prefer-dist

# --- Image finale -----------------------------------------------------------
FROM php:8.3-cli

WORKDIR /app

# Outils de base (optionnel)
RUN apt-get update && apt-get install -y \
    git \
    unzip \
 && rm -rf /var/lib/apt/lists/*

# On récupère seulement vendor depuis le stage composer
COPY --from=vendor /app/vendor /app/vendor

# On copie le reste du code
COPY . /app

# Commande par défaut : on valide tous les JSON dans data/input
CMD ["php", "bin/console", "app:validate:companies", "data/input"]
