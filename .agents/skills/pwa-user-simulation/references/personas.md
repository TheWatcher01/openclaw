# Persona Definitions

Two archetypal personas for PWA user simulation. Select based on the target journey.

---

## Persona 1 — Visiteur Anonyme (Public)

| Attribute                 | Value                                                                                   |
| ------------------------- | --------------------------------------------------------------------------------------- |
| **Name**                  | Marie, bénévole associative                                                             |
| **Device**                | iPhone 15 (390×844 viewport)                                                            |
| **Connection**            | 4G (unstable, simulate with throttling)                                                 |
| **Context**               | PWA installée via "Ajouter à l'écran d'accueil"                                         |
| **Technical level**       | Faible — utilise surtout le téléphone                                                   |
| **Goal**                  | Découvrir les subventions disponibles, simuler son éligibilité, s'abonner au calendrier |
| **Frustration threshold** | Très bas — abandonne après 2 frictions                                                  |

### Journey Routes (ordered)

| Step | Route                 | Actions                                        | Success Criteria                                           |
| ---- | --------------------- | ---------------------------------------------- | ---------------------------------------------------------- |
| 1    | `/`                   | Lire landing page, comprendre la value prop    | CTA visible above the fold, temps de lecture < 10s         |
| 2    | `/calendar`           | Explorer calendrier, filtrer par statut/région | Filtres accessibles, résultats mis à jour sans full reload |
| 3    | `/subventions/[slug]` | Lire le détail d'une subvention                | Informations clés visibles (montant, date, organisme)      |
| 4    | `/simulator`          | Remplir le formulaire de simulation            | Formulaire simple, feedback immédiat, résultat clair       |
| 5    | `/onboarding`         | S'inscrire / commencer onboarding              | Parcours fluide, pas de blocage                            |
| 6    | `/calendar/embed`     | Voir le calendrier embarqué                    | Rendu correct en iframe, responsive                        |
| 7    | `/developer`          | Consulter la page développeur                  | Documentation API claire                                   |

### Viewport & Emulation

```
Playwright: --device="iPhone 15"
Chrome DevTools: emulate({ device: "iPhone 15" })
Viewport: 390×844, touch enabled, deviceScaleFactor: 3
```

---

## Persona 2 — Admin Asso LEA (Authenticated)

| Attribute                 | Value                                                                               |
| ------------------------- | ----------------------------------------------------------------------------------- |
| **Name**                  | Thomas, coordinateur Asso LEA                                                       |
| **Device**                | Desktop Linux (1920×1080 viewport)                                                  |
| **Connection**            | Fibre (stable)                                                                      |
| **Context**               | Navigateur Chrome, multi-onglets                                                    |
| **Technical level**       | Moyen — à l'aise avec les outils web                                                |
| **Goal**                  | Gérer les subventions, suivre les échéances, exporter les données, configurer l'app |
| **Frustration threshold** | Moyen — tolère des workflows complexes si logiques                                  |

### Journey Routes (ordered)

| Step | Route                  | Actions                                    | Success Criteria                                                |
| ---- | ---------------------- | ------------------------------------------ | --------------------------------------------------------------- |
| 1    | `/admin/login`         | Se connecter avec email/password           | Formulaire accessible, erreurs claires, redirect vers dashboard |
| 2    | `/admin/dashboard`     | Consulter les stats et alertes             | Données à jour, widgets lisibles, chargement < 2s               |
| 3    | `/admin/subventions`   | Lister, filtrer, trier les subventions     | Table paginée, filtres URL-driven (Nuqs), actions CRUD          |
| 4    | `/admin/subventions`   | Créer une nouvelle subvention (formulaire) | Validation Zod, feedback toast, redirect                        |
| 5    | `/admin/checklists`    | Gérer les checklists d'une subvention      | Items cochables, sauvegarde auto                                |
| 6    | `/admin/simulator`     | Tester le simulateur d'éligibilité         | Résultats cohérents, export possible                            |
| 7    | `/admin/ai-autofill`   | Tester l'auto-remplissage IA               | Upload document, extraction, review                             |
| 8    | `/admin/documents`     | Consulter les documents                    | Liste, preview, actions                                         |
| 9    | `/admin/exports`       | Exporter données (CSV, iCal, PDF)          | Download fonctionnel, feedback toast                            |
| 10   | `/admin/settings`      | Modifier les paramètres                    | Formulaire settings, sauvegarde                                 |
| 11   | `/admin/settings/team` | Gérer l'équipe                             | Invitations, rôles, suppression                                 |

### Authentication Flow

```
1. Navigate to /admin/login
2. Fill email + password fields
3. Submit → expect redirect to /admin/dashboard
4. Verify auth-token cookie is set (HttpOnly JWT)
5. All /admin/* routes should now be accessible
```

### Viewport

```
Playwright: --viewport-size="1920x1080"
Chrome DevTools: default desktop viewport
```

---

## Persona Selection Guide

| Scenario                                           | Persona                              |
| -------------------------------------------------- | ------------------------------------ |
| Testing public-facing pages, SEO, first impression | Visiteur Anonyme                     |
| Testing admin workflows, CRUD, data management     | Admin Asso LEA                       |
| Full surface audit                                 | Both personas sequentially           |
| Mobile-specific issues                             | Visiteur Anonyme (mobile viewport)   |
| Auth flow testing                                  | Admin Asso LEA                       |
| Performance under constraints                      | Visiteur Anonyme (throttled network) |
