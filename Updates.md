# Updates

## 2025-01-08 15:36
- Added resource inventory system to track gathered resources
- Modified ResourceManager to maintain resource counts
- Updated resource gathering to display total supplies after each gather

## 2025-01-08 15:38
- Added HUD display for resource counts in top-right corner
- Created resource display labels for each resource type

## 2025-01-08 15:45
- Implementiert einfaches Bausystem für Häuser
- Hinzugefügt: House.tscn mit weißem Block-Modell
- Hinzugefügt: BuildingManager für Gebäudeplatzierung
- Kosten pro Haus: 50 Holz, 10 Fasern
- Vorschau-System beim Platzieren von Gebäuden

## 2025-01-08 15:55
- Hinzugefügt: Baumenü im HUD
- Implementiert: Umschaltung zwischen Bau- und Sammelmodus
- Verbessert: Klare visuelle Trennung der Modi durch Button-Status
- Optimiert: Ressourcensammlung und Gebäudeplatzierung funktionieren nun getrennt

## 2025-01-08 16:05
- Hinzugefügt: Ground.tscn als dedizierte Bauebene
- Verbessert: Gebäude snappen nun korrekt auf Bodenhöhe
- Optimiert: Kollisionsmasken für präzise Gebäudeplatzierung
- Angepasst: Bodenebene mit grüner Textur für bessere Sichtbarkeit

## 2025-01-08 16:15
- Hinzugefügt: Holzfäller-Hütte als automatisches Ressourcengebäude
- Implementiert: Automatische Holzernte im 2-Einheiten-Radius
- Erweitert: Gebäudeauswahl im Baumenü
- Optimiert: BuildingManager für verschiedene Gebäudetypen
- Kosten Holzfäller: 60 Holz
- Erntegeschwindigkeit: 1 Holz pro Sekunde

## 2025-01-08 16:25
- Verbessert: Ressourcen haben jetzt 3 Erntevorgänge
- Implementiert: Ressourcen verschwinden nach Erschöpfung
- Hinzugefügt: Visuelle Rückmeldung durch abnehmende Transparenz
- Optimiert: Verzögertes Entfernen für bessere Spielerfahrung

## 2025-01-08 16:35
- Behoben: Absturz beim Entfernen erschöpfter Ressourcen
- Verbessert: Sicheres Entfernen von Ressourcen
- Hinzugefügt: Sofortige Kollisionsdeaktivierung
- Optimiert: Holzfäller-Logik für erschöpfte Ressourcen

## 2025-01-08 16:45
- Verbessert: Holzfäller erntet jetzt nur noch Holz-Ressourcen
- Hinzugefügt: Ressourcentyp-Überprüfung vor dem Ernten
- Optimiert: Saubere Trennung der Ressourcentypen
- Behoben: Unbeabsichtigtes Ernten anderer Ressourcen

## 2025-01-08 16:55
- Verbessert: Holzfäller startet erst nach Platzierung mit der Ernte
- Implementiert: Aktivierungssystem für Gebäude
- Hinzugefügt: Vorschau-Status für neue Gebäude
- Optimiert: Klare Trennung zwischen Vorschau und aktivem Gebäude

## 2025-01-08 17:05
- Überarbeitet: Neues horizontales Baumenü am unteren Bildschirmrand
- Verbessert: Direkte Gebäudeauswahl ohne Moduswechsel
- Hinzugefügt: Automatische Button-Deaktivierung bei fehlenden Ressourcen
- Implementiert: Toggle-Funktion für Gebäudeauswahl (erneutes Klicken deaktiviert)
- Optimiert: Visuelle Hervorhebung des aktuell ausgewählten Gebäudes

## 2025-01-08 17:15
- Behoben: Unbeabsichtigte Gebäudeplatzierung beim Klicken auf UI
- Verbessert: UI-Klick-Erkennung im BuildingManager
- Hinzugefügt: Sichere Unterscheidung zwischen UI- und Welt-Klicks
- Optimiert: Bessere Benutzerinteraktion beim Abbrechen der Platzierung
