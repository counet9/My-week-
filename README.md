# Ma Semaine V4 — Stable (GitHub Pages + Supabase)

Cette version recrée l'interface Ma Semaine avec le planning glissant sur deux semaines, les tâches ponctuelles, les tâches permanentes, l'historique, les filtres, les statistiques, la sauvegarde/import et la synchronisation Supabase.

## Important : conserver le compte et les données

Pour garder le compte qui existe déjà et les données enregistrées, **réutilise le même projet Supabase** (`https://urfkbkagveecawwejjqq.supabase.co`) et la même clé publique que l'application précédente. Créer un nouveau dépôt GitHub ne nécessite pas de créer un nouveau projet Supabase.

La configuration Supabase est saisie dans l'application et conservée localement sur chaque appareil. Il faut la saisir une fois sur l'iPhone et une fois sur l'iPad, puis se connecter avec le même e-mail et le même mot de passe sur les deux.

N'insère jamais une clé secrète `service_role` dans le frontend. Utilise la clé `publishable` ou l'ancienne clé `anon`.

## Fichiers

- `index.html` : application complète et interface.
- `icon.svg` : icône.
- `manifest.webmanifest` : configuration installable PWA.
- `sw.js` : cache de l'interface uniquement (jamais les données Supabase).
- `schema.sql` : migration additive pour `starts_on`, RLS et Realtime.

## Déploiement GitHub Pages

1. Crée un dépôt GitHub, par exemple `Ma-semaine-v4`.
2. Téléverse les fichiers et dossiers de ce répertoire à la racine du dépôt (`index.html`, `schema.sql`, `icon.svg`, `manifest.webmanifest`, `sw.js`, `README.md`).
3. Dans **Settings → Pages**, choisis **Deploy from a branch**, puis `main` et `/ (root)`.
4. Ouvre l'URL GitHub Pages donnée par GitHub. L'URL sera de la forme `https://TON-UTILISATEUR.github.io/NOM-DU-DEPOT/`.
5. Dans l'application, ouvre « Configurer Supabase », vérifie l'URL déjà préremplie et colle la clé publique. Enregistre.
6. Connecte-toi avec le compte Supabase existant.
7. Répète les étapes 5 et 6 sur le deuxième appareil. Sur iPhone/iPad, l'installation se fait depuis le menu de partage du navigateur, puis « Sur l'écran d'accueil ».

## Base Supabase — précautions

1. Avant de toucher au SQL, ouvre **Supabase → SQL Editor** et garde une copie/export de la structure actuelle. Le script ne supprime pas de table ni de données.
2. Si les tables `tasks` et `recurring_tasks` existent déjà, le script ajoute seulement `starts_on` à `recurring_tasks` et installe les policies nommées par ce projet.
3. Exécute `schema.sql` dans le SQL Editor. Lis la liste des policies retournée à la fin : si des anciennes policies non nommées par ce script autorisent largement les accès, corrige-les après vérification. Les policies restrictives de garde-fou du script imposent `auth.uid() = user_id`.
4. Ne supprime pas `planner_state` si elle est utilisée par l'ancienne application ; cette version ne s'en sert pas.

## Fonctionnement des semaines

- L'onglet « Cette semaine » affiche la semaine actuelle du lundi au dimanche.
- « Semaine prochaine » permet de préparer la semaine suivante.
- Les tâches ponctuelles sont enregistrées avec `week_start`, donc elles restent attachées à leur semaine.
- Les tâches permanentes sont enregistrées dans `recurring_tasks`; leur modèle s'affiche chaque semaine à partir de `starts_on`. La coche est sauvegardée séparément dans `tasks` avec `recurring_id` et `week_start`.
- Le lundi à 00h, les deux onglets suivent naturellement les nouvelles dates. Les données passées restent dans Supabase et peuvent être consultées via « Historique ».
- Le bouton de suppression d'une tâche permanente supprime le modèle récurrent et ses occurrences enregistrées. Cette action est volontairement confirmée.

## Test recommandé avant utilisation quotidienne

1. Connecte-toi sur un appareil et vérifie que l'ancien planning se charge.
2. Ajoute une tâche ponctuelle et coche-la ; vérifie dans Supabase qu'une ligne `tasks` est créée/modifiée avec le bon `user_id` et `week_start`.
3. Ajoute une tâche « Chaque semaine », coche-la dans la semaine actuelle, puis vérifie qu'elle est décochée dans la semaine prochaine.
4. Ouvre le site sur le second appareil et vérifie les changements.
5. Teste l'export de sauvegarde avant d'importer un fichier ancien.

## Limite connue concernant les sauvegardes anciennes

L'import intégré accepte le format JSON exporté par cette version et les champs habituels `tasks` / `recurring_tasks`. Si une sauvegarde de la toute première V3 possède une structure différente, conserve-la et ne l'importe pas à l'aveugle : il faudra examiner son format et adapter le convertisseur.
