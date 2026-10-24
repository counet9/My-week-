# Ma Semaine V4 — Stable

Application web/PWA de planning hebdomadaire pour GitHub Pages, avec Supabase Auth et synchronisation des tâches.

## Les deux règles à respecter

1. **Garde le projet Supabase existant.** Ne crée pas un nouveau projet Supabase et ne supprime aucune table : c'est ce projet qui contient ton compte et les données déjà enregistrées.
2. **L'URL et la clé publique doivent venir du même projet.** Dans Supabase, ouvre ton projet puis `Settings → API Keys`. Copie l'URL API affichée sur le tableau de bord et sa `Publishable key` (ou l'ancienne clé `anon`). N'utilise jamais une `Secret key` ou `service_role` dans le navigateur.

La configuration est enregistrée séparément dans le navigateur de chaque appareil. Il faut la vérifier sur l'iPhone et sur l'iPad, puis se connecter avec le même compte.

## Fichiers

- `index.html` : application et logique de connexion, tâches et semaines.
- `schema.sql` : migration Supabase non destructive, colonnes, jour numérique, sécurité RLS et Realtime.
- `icon.svg`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png` : icônes de l'application.
- `manifest.webmanifest` : configuration PWA.
- `sw.js` : service worker avec mise à jour réseau prioritaire de l'interface. Les données et identifiants Supabase ne sont pas mis en cache par le service worker.
- `README.md` : ces instructions.

## Mise à jour du dépôt GitHub existant

Il n'est pas nécessaire de supprimer le dépôt GitHub ou d'en créer un nouveau si le dépôt actuel fonctionne déjà.

1. Décompresse `ma-semaine-v4-stable.zip`.
2. Ouvre le dépôt GitHub qui héberge Ma Semaine.
3. Choisis `Add file → Upload files` et charge les fichiers présents dans le dossier décompressé **à la racine** du dépôt. Accepte le remplacement des fichiers de même nom.
4. Vérifie que les fichiers suivants sont à la racine : `index.html`, `schema.sql`, `icon.svg`, `icon-192.png`, `icon-512.png`, `apple-touch-icon.png`, `manifest.webmanifest`, `sw.js`.
5. Fais `Commit changes` sur la branche `main`.
6. Dans `Settings → Pages`, vérifie `Deploy from a branch`, branche `main`, dossier `/ (root)`.
7. Attends que GitHub Pages termine le déploiement puis recharge le site. Le service worker est configuré pour privilégier la version en ligne de `index.html`.

## Mise à niveau Supabase

Fais d'abord une sauvegarde si possible. Ensuite :

1. Ouvre **le projet Supabase qui contient déjà ton compte**.
2. Va dans `SQL Editor` et crée une nouvelle requête.
3. Ouvre le fichier `schema.sql` de ce paquet, copie son contenu complet et colle-le dans l'éditeur.
4. Lis le script une fois, puis appuie sur `Run`.
5. Si Supabase signale une erreur, arrête-toi et conserve le texte exact de l'erreur. Ne supprime pas les tables et ne crée pas un autre projet pour la contourner.

Le script ne supprime aucune table ni aucune ligne. Il ajoute les colonnes manquantes, normalise le champ `day` si celui-ci était en texte, installe les policies RLS nommées par Ma Semaine et active Realtime si la publication existe. Les anciennes policies portant d'autres noms ne sont pas supprimées ; les policies restrictives de garde-fou ajoutées ici limitent les lignes à `auth.uid() = user_id`.

La V4 utilise le format numérique `day = 0` pour lundi, `1` pour mardi, ..., `6` pour dimanche. Le script essaie de reconnaître et de convertir les anciennes valeurs textuelles. Il normalise aussi les valeurs 1–7 en 0–6 uniquement si les données montrent clairement cette convention (présence de 7 et absence de 0 dans les deux tables). Si tes anciennes données utilisent une convention différente, vérifie quelques lignes avant de modifier manuellement quoi que ce soit.

## Configuration de l'application

1. Ouvre le site GitHub Pages.
2. Dans `Configurer Supabase`, renseigne l'URL copiée depuis le tableau de bord du projet et la clé `Publishable` du même projet.
3. Appuie sur `Enregistrer`.
4. Connecte-toi avec ton e-mail et ton mot de passe existants.
5. Répète la configuration sur l'autre appareil avec la même URL, la même clé publique et le même compte.

Si la connexion est verte mais qu'une erreur de structure apparaît, cela signifie que l'authentification fonctionne mais qu'une requête de données est encore incompatible. Garde le message d'erreur exact pour diagnostiquer le champ concerné.

## Fonctionnement des semaines

- `Cette semaine` affiche du lundi au dimanche.
- `Semaine prochaine` permet de préparer les sept jours suivants.
- Une tâche ponctuelle est enregistrée dans `tasks` avec son `week_start` et ne se recopie pas la semaine suivante.
- Une tâche permanente est enregistrée dans `recurring_tasks` avec une date de début `starts_on`; elle apparaît chaque semaine à partir de cette date.
- La coche d'une tâche permanente est enregistrée par semaine dans `tasks`, avec `week_start` et `recurring_id`.
- La date des deux onglets glisse automatiquement le lundi. Les anciennes semaines restent stockées et peuvent être consultées avec `Historique`.
- Supprimer une tâche permanente supprime son modèle pour l'avenir. Les occurrences déjà enregistrées sont détachées du modèle et conservées dans leur semaine historique.

## Vérifications après déploiement

1. Confirme que le statut `Connecté · synchronisé` est affiché.
2. Ajoute une tâche ponctuelle, coche-la, puis décoche-la.
3. Ajoute une tâche permanente et vérifie qu'elle apparaît dans la semaine actuelle et la suivante, selon sa date de début.
4. Coche cette tâche dans une semaine et vérifie qu'elle reste décochée dans l'autre.
5. Ouvre l'application sur l'autre appareil et vérifie que les modifications apparaissent.
6. Exporte une sauvegarde JSON et conserve-la dans un endroit sûr.

## Sécurité

Le frontend n'accepte que des clés client `publishable` ou `anon`. N'y colle jamais une clé `secret` ou `service_role`. La clé publique peut être utilisée dans le navigateur uniquement avec des policies RLS correctes.
