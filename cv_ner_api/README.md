# CV NER API — Guide de déploiement

## 1. Installation Python

```bash
cd cv_ner_api/

# Créer un environnement virtuel
python -m venv venv
source venv/bin/activate        # Linux/Mac
# .\venv\Scripts\activate       # Windows

# Installer les dépendances
pip install -r requirements.txt

# Télécharger le modèle spaCy français (recommandé)
python -m spacy download fr_core_news_md

# Ou le petit modèle (plus léger)
python -m spacy download fr_core_news_sm
```

## 2. Lancer l'API

```bash
python app.py
# → Démarre sur http://0.0.0.0:5000
```

## 3. Tester l'API

```bash
curl -X POST http://localhost:5000/extract-skills \
  -H "Content-Type: application/json" \
  -d '{"text": "Développeur Flutter avec 3 ans d expérience en Dart, Firebase, REST API et Agile."}'
```

Réponse attendue :
```json
{
  "skills": ["Agile", "Dart", "Firebase", "Flutter", "REST"],
  "tech_skills": ["agile", "dart", "firebase", "flutter", "rest api"],
  "ner_entities": [{"text": "Flutter", "label": "MISC"}, ...],
  "noun_phrases": ["ans d expérience", ...]
}
```

## 4. Configuration Flutter selon l'environnement

Dans `cv_service.dart`, changez `_nerApiBase` :

| Environnement              | URL                          |
|---------------------------|------------------------------|
| Émulateur Android         | `http://10.0.2.2:5000`       |
| Appareil physique (LAN)   | `http://192.168.x.x:5000`    |
| iOS Simulator             | `http://localhost:5000`      |
| Production                | `https://votre-api.com`      |

## 5. Déploiement production (optionnel)

### Option A — Railway / Render (gratuit)
1. Push le dossier `cv_ner_api/` sur GitHub
2. Connecter à Railway.app ou Render.com
3. Ajouter les commandes de build :
   ```
   pip install -r requirements.txt && python -m spacy download fr_core_news_sm
   ```
4. Start command : `gunicorn app:app`

### Option B — Docker
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt && python -m spacy download fr_core_news_sm
COPY app.py .
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
```

## Notes importantes

- Sur **Web Flutter**, `syncfusion_flutter_pdf` extrait bien le texte depuis les bytes
- Si l'API Flask est inaccessible, `cv_service.dart` bascule automatiquement sur le fallback local (dictionnaire de mots-clés techniques)
- `google_mlkit_entity_extraction` a été **supprimé** car il extrait des entités structurées (dates, téléphones...) et non des compétences