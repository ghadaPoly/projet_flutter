"""
CV NER API — extrait les compétences d'un texte de CV avec spaCy.
POST /extract-skills  { "text": "..." }  →  { "skills": [...], "entities": [...] }
"""

from flask import Flask, request, jsonify
import spacy
from flask_cors import CORS  # ← AJOUTER CETTE LIGNE
import re

app = Flask(__name__)
CORS(app)

# Charge le modèle français (ou multilingue en fallback)
try:
    nlp = spacy.load("fr_core_news_md")
    print("✅ Modèle fr_core_news_md chargé")
except OSError:
    try:
        nlp = spacy.load("fr_core_news_sm")
        print("✅ Modèle fr_core_news_sm chargé")
    except OSError:
        nlp = spacy.load("en_core_web_sm")
        print("⚠️  Fallback: modèle anglais chargé")


# ─── Dictionnaire de compétences techniques ────────────────────────────────
TECH_SKILLS = {
    # Langages
    "python", "java", "dart", "javascript", "typescript", "kotlin", "swift",
    "c++", "c#", "php", "ruby", "rust", "go", "scala", "r",
    # Frameworks / Mobile
    "flutter", "react", "react native", "angular", "vue", "django", "flask",
    "spring", "laravel", "express", "fastapi", "nest.js",
    # Cloud / DevOps
    "firebase", "aws", "azure", "gcp", "docker", "kubernetes", "ci/cd",
    "terraform", "ansible", "jenkins", "github actions",
    # Bases de données
    "sql", "mysql", "postgresql", "mongodb", "redis", "firebase",
    "sqlite", "oracle", "elasticsearch",
    # Outils
    "git", "github", "gitlab", "figma", "jira", "postman", "linux",
    "rest api", "graphql", "json", "xml",
    # Méthodes
    "agile", "scrum", "kanban", "tdd", "devops", "microservices", "mvc",
    # IA / Data
    "machine learning", "deep learning", "tensorflow", "pytorch",
    "pandas", "numpy", "scikit-learn", "nlp", "computer vision",
    # Mobile
    "android", "ios", "mobile", "pwa",
}

# ─── Patterns de noms propres techniques (regex) ───────────────────────────
TECH_PATTERNS = [
    r'\bFlutter\b', r'\bDart\b', r'\bFirebase\b', r'\bReact\b',
    r'\bAndroid\b', r'\biOS\b', r'\bPython\b', r'\bJava\b',
    r'\bKotlin\b', r'\bSwift\b', r'\bNodeJS\b', r'\bNode\.js\b',
    r'\bDocker\b', r'\bKubernetes\b', r'\bAWS\b', r'\bAzure\b',
    r'\bGCP\b', r'\bSQL\b', r'\bGit\b', r'\bFigma\b', r'\bAgile\b',
    r'\bScrum\b', r'\bAPI\b', r'\bREST\b', r'\bJSON\b',
]


def extract_ner_entities(text: str) -> list[dict]:
    """Extrait les entités nommées avec spaCy."""
    doc = nlp(text[:100_000])   # limite pour la perfo
    entities = []
    seen = set()

    for ent in doc.ents:
        word = ent.text.strip()
        key = word.lower()
        # Garde MISC (divers), ORG, PRODUCT — types utiles pour un CV
        if ent.label_ in ("MISC", "ORG", "PRODUCT", "LOC", "GPE") and key not in seen:
            if len(word) > 2:
                entities.append({"text": word, "label": ent.label_})
                seen.add(key)

    return entities


def extract_tech_skills(text: str) -> list[str]:
    """Détecte les compétences techniques par dictionnaire + regex."""
    found = set()
    lower = text.lower()

    # Correspondance dictionnaire
    for skill in TECH_SKILLS:
        if skill in lower:
            # Normalise la casse : garde la version originale du texte
            pattern = re.compile(re.escape(skill), re.IGNORECASE)
            match = pattern.search(text)
            found.add(match.group(0) if match else skill)

    # Correspondance regex (noms propres techniques)
    for pattern in TECH_PATTERNS:
        matches = re.findall(pattern, text)
        found.update(matches)

    return sorted(found)


def extract_noun_phrases(text: str) -> list[str]:
    """Extrait les groupes nominaux pertinents via spaCy."""
    doc = nlp(text[:50_000])
    phrases = set()

    for chunk in doc.noun_chunks:
        phrase = chunk.text.strip()
        # Filtre : 2–5 mots, pas trop courts, pas de stop words seuls
        words = phrase.split()
        if 2 <= len(words) <= 5 and len(phrase) > 4:
            # Garde si au moins un token n'est pas un stop word
            has_content = any(not token.is_stop for token in nlp(phrase))
            if has_content:
                phrases.add(phrase)

    return sorted(phrases)[:30]   # Max 30 pour ne pas noyer les vrais skills


@app.route("/extract-skills", methods=["POST"])
def extract_skills():
    data = request.get_json(force=True)
    text = data.get("text", "").strip()

    if not text or len(text) < 10:
        return jsonify({"error": "Texte trop court ou vide"}), 400

    # 1. NER spaCy → entités nommées
    entities = extract_ner_entities(text)

    # 2. Dictionnaire + regex → compétences techniques
    tech_skills = extract_tech_skills(text)

    # 3. Groupes nominaux → autres mots-clés contextuels
    noun_phrases = extract_noun_phrases(text)

    # Fusion : on priorise les tech skills, on ajoute les entités NER
    all_skills = set(tech_skills)
    for ent in entities:
        all_skills.add(ent["text"])

    return jsonify({
        "skills": sorted(all_skills),
        "tech_skills": tech_skills,
        "ner_entities": entities,
        "noun_phrases": noun_phrases,
    })


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "model": nlp.meta.get("name", "unknown")})


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)