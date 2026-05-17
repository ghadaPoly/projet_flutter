from flask import Flask, request, jsonify
import spacy
from flask_cors import CORS 
import re

app = Flask(__name__)
CORS(app)

# Charger le modèle 
try:
    #medium
    nlp = spacy.load("fr_core_news_md")
    print(" Modèle fr_core_news_md chargé")
except OSError:
    try:
        #small
        nlp = spacy.load("fr_core_news_sm")
        print(" Modèle fr_core_news_sm chargé")
    except OSError:
        nlp = spacy.load("en_core_web_sm")
        print("  Fallback: modèle anglais chargé")


# Dict de compétences techniques
TECH_SKILLS = {
    "python", "java", "dart", "javascript", "typescript", "kotlin", "swift",
    "c++", "c#", "php", "ruby", "rust", "go", "scala", "r",
    "flutter", "react", "react native", "angular", "vue", "django", "flask",
    "spring", "laravel", "express", "fastapi", "nest.js",
    "firebase", "aws", "azure", "gcp", "docker", "kubernetes", "ci/cd",
    "terraform", "ansible", "jenkins", "github actions",
    "sql", "mysql", "postgresql", "mongodb", "redis", "firebase",
    "sqlite", "oracle", "elasticsearch",
    "git", "github", "gitlab", "figma", "jira", "postman", "linux",
    "rest api", "graphql", "json", "xml",
    "agile", "scrum", "kanban", "tdd", "devops", "microservices", "mvc",
    "machine learning", "deep learning", "tensorflow", "pytorch",
    "pandas", "numpy", "scikit-learn", "nlp", "computer vision",
    "android", "ios", "mobile", "pwa",
}
# respecte la casse
TECH_PATTERNS = [
    r'\bFlutter\b', r'\bDart\b', r'\bFirebase\b', r'\bReact\b',
    r'\bAndroid\b', r'\biOS\b', r'\bPython\b', r'\bJava\b',
    r'\bKotlin\b', r'\bSwift\b', r'\bNodeJS\b', r'\bNode\.js\b',
    r'\bDocker\b', r'\bKubernetes\b', r'\bAWS\b', r'\bAzure\b',
    r'\bGCP\b', r'\bSQL\b', r'\bGit\b', r'\bFigma\b', r'\bAgile\b',
    r'\bScrum\b', r'\bAPI\b', r'\bREST\b', r'\bJSON\b',
]


def extract_ner_entities(text: str) -> list[dict]:
    # ner avec spacy
    # nlp analyse le texte avec spacy
    doc = nlp(text[:100_000]) 
    entities = []
    seen = set()
# entities found by spacy
    for ent in doc.ents:
        word = ent.text.strip()
        key = word.lower()
        if ent.label_ in ("MISC", "ORG", "PRODUCT", "LOC", "GPE") and key not in seen:
            if len(word) > 2:
                entities.append({"text": word, "label": ent.label_})
                seen.add(key)

    return entities

def extract_tech_skills(text: str) -> list[str]:
    #Détecte les compétences  par dict w regex
    found = set()
    lower = text.lower()

    # Correspondance au dict
    for skill in TECH_SKILLS:
        if skill in lower:
            # ynahi les caracteres speciaux
            pattern = re.compile(re.escape(skill), re.IGNORECASE)
            match = pattern.search(text)
            found.add(match.group(0) if match else skill)

    for pattern in TECH_PATTERNS:
        matches = re.findall(pattern, text)
        found.update(matches)

    return sorted(found)

#plus lourd
def extract_noun_phrases(text: str) -> list[str]:
    # permet de capter des grp de mots (dev mob ...)
    doc = nlp(text[:50_000])
    phrases = set()

    for chunk in doc.noun_chunks:
        phrase = chunk.text.strip()
        words = phrase.split()
        # au moins 2 mots max 5 et plus que 4 car
        if 2 <= len(words) <= 5 and len(phrase) > 4:
            has_content = any(not token.is_stop for token in nlp(phrase))
            if has_content:
                phrases.add(phrase)

    return sorted(phrases)[:30]


@app.route("/extract-skills", methods=["POST"])
def extract_skills():
    data = request.get_json(force=True)
    text = data.get("text", "").strip()

    if not text or len(text) < 10:
        return jsonify({"error": "Texte trop court ou vide"}), 400

    # 1. ner spacy
    entities = extract_ner_entities(text)

    # 2. Dict + regex 
    tech_skills = extract_tech_skills(text)

    # 3. Groupes nominaux (mobile dev) 
    noun_phrases = extract_noun_phrases(text)

    # Fusion :  tech skills + entités NER
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