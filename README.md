# Yesplan Dashboard voor Home Assistant

Dagplanning en weekplanning voor De Nieuwe Vorst, gebouwd op de Yesplan REST API.

## Bestanden

| Bestand | Omschrijving |
|---|---|
| `config.json` | **Configuratie** — API key, URL, zalen, output map |
| `dagplanning.sh` | Script dat data van vandaag ophaalt |
| `weekplanning.sh` | Script dat data van de komende 7 dagen ophaalt |
| `dagplanning.html` | Dashboard voor vandaag |
| `weekplanning.html` | Dashboard met datumkiezer (komende 7 dagen) |

## Mapstructuur

```
/config/www/yesplan/
├── config.json
├── dagplanning.sh
├── weekplanning.sh
├── dagplanning.html
├── weekplanning.html
├── dagplanning.json     ← gegenereerd door dagplanning.sh
└── weekplanning.json     ← gegenereerd door weekplanning.sh
```

## Installatie

### 1. Vereisten op de HA host
```bash
apt install curl jq
```

### 2. Map aanmaken en bestanden plaatsen
```bash
mkdir -p /config/www/yesplan
cp config.json dagplanning.sh weekplanning.sh dagplanning.html weekplanning.html /config/www/yesplan/
chmod +x /config/www/yesplan/*.sh
```

### 3. Configuratie aanpassen
Bewerk `/config/www/yesplan/config.json`:
```json
{
  "api_key": "JOUW_YESPLAN_API_KEY",
  "base_url": "https://JOUW_INSTALLATIE.yesplan.nl/api",
  "locaties": [
    "De Nieuwe Vorst",
    "Grote zaal",
    "Kleine zaal",
    "Leesstudio",
    "Rode salon",
    "Balkonkamer"
  ],
  "output_dir": "/config/www/yesplan"
}
```

### 4. Scripts uitvoeren
```bash
bash /config/www/yesplan/dagplanning.sh
bash /config/www/yesplan/weekplanning.sh
```

### 5. Cronjobs instellen
```bash
crontab -e
```
Voeg toe:
```
# Dagplanning: elk uur tussen 6:00 en 22:00
0 6-22 * * * bash /config/www/yesplan/dagplanning.sh

# Weekplanner: elke ochtend om 5:00
0 5 * * * bash /config/www/yesplan/weekplanning.sh
```

### 6. Lovelace dashboard
Voeg toe aan je dashboard YAML:
```yaml
views:
  - title: Dagplanning
    path: dagplanning
    panel: true
    cards:
      - type: iframe
        url: /local/yesplan/dagplanning.html
        aspect_ratio: "0%"

  - title: Weekplanner
    path: weekplanning
    panel: true
    cards:
      - type: iframe
        url: /local/yesplan/weekplanning.html
        aspect_ratio: "0%"
```

## Werking

De scripts doen het volgende:
1. Lezen `config.json` voor API key, URL en zaallijst
2. Halen events op via de Yesplan REST API (per dag, per zaal)
3. Halen voor elk event het volledige tijdschema op via `/schedule`
4. Halen resources op via `/resourcebookings`
5. Slaan alles op als JSON in `output_dir`

De HTML pagina's lezen de gegenereerde JSON en renderen die in de browser.
Geen directe verbinding met Yesplan vanuit de browser — alles loopt via de server.

## Zalen aanpassen

Wijzig de `locaties` array in `config.json`. De volgorde in de array bepaalt de weergavevolgorde.
