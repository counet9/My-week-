# Étapes Supabase — Ma Semaine V4 Stable

**Ne crée pas de projet Supabase neuf et ne supprime aucune table.** Utilise le projet qui contient déjà le compte utilisé dans Ma Semaine.

## Exécuter la migration

1. Dans Supabase, ouvre le projet existant.
2. Choisis `SQL Editor` puis `New query`.
3. Depuis ce paquet, ouvre `schema.sql` et copie son contenu complet.
4. Colle tout le contenu dans SQL Editor, puis appuie sur `Run`.
5. Si l'exécution réussit, le résultat final affiche les policies présentes pour `tasks` et `recurring_tasks`.
6. Si une erreur apparaît, ne lance pas d'autres scripts en parallèle et ne supprime rien ; garde le texte exact de l'erreur.

Le script est idempotent pour ses objets nommés et non destructif vis-à-vis des données : il ne contient aucun `DROP TABLE`, `TRUNCATE` ou suppression de ligne. Il peut modifier le type de `day` s'il est textuel afin de le rendre numérique, et tente de convertir les libellés des jours en nombres.

## Configurer le frontend

Dans Ma Semaine, ouvre `Configurer Supabase` :

- URL : copie l'URL API montrée dans le tableau de bord du projet.
- Clé : prends la `Publishable key` de `Settings → API Keys` (ou l'ancienne `anon` key du même projet).
- N'utilise jamais la `Secret key` / `service_role`.

Enregistre puis connecte-toi avec le compte existant. Répète sur le second appareil.
