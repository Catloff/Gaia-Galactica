# Updates

## 2024-01-07
- Kamerasteuerung hinzugefügt:
  - Freie Rotation um den Planeten mit Maus (linke Maustaste halten und ziehen) oder Touch (Finger ziehen)
  - Zoom-Funktion mit Mausrad
  - Kamera rotiert relativ zum Planetenzentrum
  - Minimaler Zoom: 10 Einheiten
  - Maximaler Zoom: 100 Einheiten

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

## 2025-01-08 17:18
- Added BerryGatherer building for automatic food resource collection
- Building costs 50 food to construct
- Automatically gathers berries within radius similar to Lumbermill

## 2025-01-08 17:19
- Added BerryGatherer to BuildingManager
- Integrated building placement system for BerryGatherer
- Updated building selection logic to include new building type

## 2025-01-08 17:21
- Added BerryGatherer button to HUD
- Added button state management for BerryGatherer (requires 50 food)
- Updated button highlighting to include BerryGatherer selection

## 2025-01-08 17:25
- Überarbeitet: Organisches Ressourcen-Spawning-System
- Implementiert: Cluster-basierte Ressourcenverteilung
- Hinzugefügt: Zufällige Cluster-Größen und -Positionen
- Optimiert: Mindestabstände zwischen Ressourcen
- Verbessert: Natürlichere Ressourcenverteilung auf der Karte

## 2025-01-08 17:35
- Verbessert: Garantierte Spawns für alle Ressourcentypen
- Implementiert: Mindestens ein Cluster pro Ressourcentyp
- Hinzugefügt: Zufällige Reihenfolge der initialen Cluster
- Optimiert: Separate Spawn-Funktion für Cluster
- Behoben: Fehlende Holz-Ressourcen

## 2025-01-08 17:43
- Renamed Fiber resource to Stone throughout the codebase
- Updated Stone resource color to gray
- Updated all UI elements to reflect the name change
- Updated building costs to use Stone instead of Fiber
- Ensured resource spawning system uses Stone type correctly


## 2025-01-08 17:45
- Hinzugefügt: Ressourcendichte-Steuerung über RESOURCE_DENSITY
- Implementiert: Dynamische Berechnung der Cluster-Anzahl
- Verbessert: Flächenbasierte Ressourcenverteilung
- Optimiert: Zufällige Variation der Cluster-Anzahl
- Debug: Logging der Spawn-Informationen

## 2025-01-08 17:46
- Added new Smeltery building for metal production
- Added metal as a new resource type
- Smeltery converts wood (2) and stone (1) into metal every 5 seconds
- Building cost: 80 wood, 40 stone
- Updated HUD to display metal count
- Added Smeltery button to building panel

## 2025-01-08 17:50
- Hinzugefügt: Förstergebäude für automatische Baumpflanzung
- Implementiert: Speicherung von Baumpositionen für Nachpflanzung
- Hinzugefügt: Scan-Funktion für existierende Bäume im Radius
- Implementiert: Automatisches Nachpflanzen alle 3 Sekunden
- Kosten: 80 Holz, 20 Stein
- Radius: 8 Einheiten (größer als Holzfäller)

## 2025-01-08 18:00
- Überarbeitet: Baumenü in drei Kategorien aufgeteilt (Ressourcengebäude, Infrastruktur, Ressourcen)
- Verbessert: Übersichtlichere Anordnung der Gebäude-Buttons
- Angepasst: Größeres Baumenü für bessere Lesbarkeit
- Optimiert: Klare visuelle Trennung der Gebäudekategorien


## 2025-01-08 18:06
- Added upgrade system to Smeltery
- Smeltery now has 3 levels with increasing efficiency:
  - Level 1: 1 metal per 5 seconds
  - Level 2: 2 metal per 4 seconds (costs 5 metal, 20 stone)
  - Level 3: 3 metal per 3 seconds (costs 10 metal, 40 stone)
- Added UI elements to show level and upgrade button
- Building gets slightly redder with each upgrade
- Resource costs stay constant (2 wood, 1 stone per operation)

## 2025-01-08 18:10
- Hinzugefügt: Abriss-Modus für Gebäude
- Implementiert: Roter Abriss-Button neben dem Baumenü
- Hinzugefügt: 50% Ressourcen-Rückerstattung beim Abreißen
- Verbessert: Rechtsklick zum Verlassen des Abriss-Modus
- Optimiert: Automatische Deaktivierung der Gebäudeauswahl im Abriss-Modus

## 2025-01-08 20:57
- Refactored ResourceManager with more specific functions:
  - Added `CanAfford` to check if player has enough resources
  - Added `PayCost` to deduct resources if affordable
  - Added `AddResources` to add resources to inventory
- Improved code organization and maintainability
- Maintained existing functionality while making the API more explicit

## 2025-01-08 20:58
- Fixed function naming in ResourceManager to follow GDScript snake_case convention
- Updated Smeltery to use new resource management functions:
  - Replaced direct inventory access with `can_afford` checks
  - Simplified resource costs using `pay_cost`
  - Improved metal production code readability
  - Enhanced upgrade system to use new API

## 2025-01-08 21:19
- Refactored HUD building cost checks to use ResourceManager's `can_afford` function
- Improved consistency in resource management across the codebase
- Removed direct inventory access from HUD building checks

## 2025-01-08 21:41
- Fixed race condition in building placement system:
  - Removed automatic building deselection from HUD's resource check
  - Added explicit building deselection after successful placement
  - Added `deselect_building` method to HUD for consistent deselection behavior
  - Improved code organization and error handling in BuildingManager

## 2025-01-08 21:45
- Refactoring: Building-System mit Basisklasse
  - Implementiert: BaseBuilding als abstrakte Basisklasse für alle Gebäude
  - Hinzugefügt: Gemeinsame Funktionalität wie Upgrade-System und UI-Verwaltung
  - Überarbeitet: Smeltery nutzt nun die Basisklasse
  - Optimiert: Verbesserte Code-Wiederverwendung und Wartbarkeit
  - Standardisiert: Einheitliche Behandlung von Gebäude-Funktionen

## 2025-01-08 21:50
- Refactoring: Gebäude auf BaseBuilding umgestellt
  - Überarbeitet: Lumbermill nutzt nun BaseBuilding
  - Überarbeitet: BerryGatherer nutzt nun BaseBuilding
  - Überarbeitet: Forester nutzt nun BaseBuilding
  - Optimiert: Gemeinsame Funktionalität in Basisklasse verschoben
  - Verbessert: Einheitliche Aktivierung und Deaktivierung
  - Standardisiert: Konsistente Gebäude-Initialisierung

## 2025-01-08 21:55
- Refactoring: Vereinheitlichtes UI-System für Gebäude
  - Implementiert: Wiederverwendbare BuildingUI-Szene
  - Verbessert: Dynamische Upgrade-Button-Aktualisierung
  - Hinzugefügt: Automatische Ressourcen-Kosten-Anzeige
  - Optimiert: Konsistentes Upgrade-System für alle Gebäude
  - Behoben: Smeltery-Upgrade-Funktionalität wiederhergestellt

## 2025-01-08 22:00
- Verbessert: UI-Positionierung für Gebäude
  - Implementiert: Dynamische UI-Position über den Gebäuden
  - Hinzugefügt: Automatische Ausrichtung zur Kamera
  - Verbessert: Zentrierte Anzeige von Level und Upgrade-Button
  - Optimiert: Sichtbarkeitssteuerung basierend auf Aktivierungsstatus
  - Angepasst: UI-Layout für bessere Lesbarkeit

## 2025-01-08 22:53
- Refactoring: Changed building system to use BuildingManager as single source of truth
- Moving building definitions (costs, categories) from BuildingHUD to BuildingManager
- Implementing centralized building registration system
- Improving maintainability by removing duplicated building costs

## 2025-01-08 22:56
- Building Cost Management Refactoring
- Removed `get_cost` functions from individual building scripts
- Centralized all building costs in BuildingManager
- Improved code maintainability by having a single source of truth for building costs

## 2025-01-09 00:01
- Dynamic Building Button Generation
- Refactored BuildingHUD to dynamically generate buttons from BuildingManager definitions
- Removed hardcoded building buttons
- Improved maintainability by automatically reflecting building changes in the UI

## 2025-01-09 00:04
- Added Fuel Resource and Refinery Building
- Added new fuel resource type
- Implemented refinery building that converts food into fuel
- Updated resource management system to handle fuel
- Added refinery to building menu under Resource category

## 2025-01-09 00:12
- Added Fuel Display to HUD
- Added fuel resource display to ResourceHUD
- Updated ResourceHUD scene with fuel label
- Connected fuel display to resource management system

## 2025-01-09 00:15
- Refinery Improvements
- Updated Refinery to extend BaseBuilding
- Added proper resource management using pay_cost API
- Implemented upgrade system with efficiency and speed improvements
- Added visual feedback with building color

## 2025-01-09 00:19
- Added Fuel Display to HUD
- Added fuel resource display to ResourceHUD
- Updated ResourceHUD scene with fuel label
- Connected fuel display to resource management system

## 2025-01-09 00:19
- Added Fuel Display to HUD
- Added fuel resource display to ResourceHUD
- Updated ResourceHUD scene with fuel label
- Connected fuel display to resource management system

## 2025-01-08 23:04
- Refactoring: Split HUD into separate components
- Created `ResourceHUD` for resource display:
  - Moved resource labels and update logic
  - Simplified resource management code
- Created `BuildingHUD` for building controls:
  - Moved building buttons and selection logic
  - Maintained building cost checks and UI updates
- Updated main `HUD`:
  - Now acts as a coordinator between components
  - Forwards signals and resource updates
- Improved code organization and maintainability
- Better separation of concerns between UI components

## 2025-01-08 23:28
- Implemented Resource Storage Limits
- Added maximum storage capacity for each resource type in ResourceManager
- Updated ResourceHUD to display current/max values for each resource
- Implemented logic to prevent exceeding storage limits when adding resources
- Initial storage limits set to:
  - Wood: 1000
  - Stone: 1000
  - Food: 500
  - Metal: 100

## 2025-01-08 23:30
- Improved Resource Value Clamping
- Replaced `min` function with `clampi` in ResourceManager
- Now ensures resource values stay between 0 and maximum storage limit
- Provides better value control and prevents negative resources

## 2025-01-08 23:32
- Updated Resource Display
- Modified ResourceHUD to dynamically show current/maximum values
- Resource display now shows format: "Resource: Current/Maximum"
- Ensures UI stays in sync with storage Limits


## 2025-01-08 23:35
- Hinzugefügt: Große, unerschöpfliche Steine als neue Ressourcenquelle
- Implementiert: Cooldown-System für das Abbauen der großen Steine (3 Sekunden)
- Hinzugefügt: 5 große Steine werden zufällig auf der Karte verteilt
- Optimiert: Große Steine geben 5 Steinressourcen pro Abbau
- Angepasst: Visuelle Darstellung der großen Steine (3x3x3 Einheiten, dunkelgrau)

## 2025-01-08 23:49
- Refactoring: Changed building system to use BuildingManager as single source of truth
- Moving building definitions (costs, categories) from BuildingHUD to BuildingManager
- Implementing centralized building registration system
- Improving maintainability by removing duplicated building costs

## 2025-01-09 00:01
- Building Cost Management Refactoring
- Removed `get_cost` functions from individual building scripts
- Centralized all building costs in BuildingManager
- Improved code maintainability by having a single source of truth for building costs

## 2025-01-09 00:04
- Dynamic Building Button Generation
- Refactored BuildingHUD to dynamically generate buttons from BuildingManager definitions
- Removed hardcoded building buttons
- Improved maintainability by automatically reflecting building changes in the UI

## 2025-01-09 00:12
- Added Fuel Resource and Refinery Building
- Added new fuel resource type
- Implemented refinery building that converts food into fuel
- Updated resource management system to handle fuel
- Added refinery to building menu under Resource category

## 2025-01-09 00:15
- Refinery Improvements
- Updated Refinery to extend BaseBuilding
- Added proper resource management using pay_cost API
- Implemented upgrade system with efficiency and speed improvements
- Added visual feedback with building color
## 2025-01-08 23:55
- Hinzugefügt: Steinbruch als neues automatisches Ressourcengebäude
- Implementiert: Automatischer Abbau von großen Steinen im 5-Einheiten-Radius
- Kosten: 40 Holz, 20 Stein
- Optimiert: Abbaurate synchronisiert mit Cooldown der großen Steine (3 Sekunden)
- Angepasst: Graue Färbung für thematische Stimmigkeit

## 2025-01-09 00:10
- Hinzugefügt: Große, nachwachsende Büsche als neue Nahrungsquelle
- Implementiert: Cooldown-System für das Ernten der großen Büsche (2 Sekunden)
- Hinzugefügt: 4 große Büsche werden zufällig auf der Karte verteilt
- Optimiert: Große Büsche geben 3 Nahrungsressourcen pro Ernte
- Angepasst: Visuelle Darstellung der großen Büsche (4x2x4 Einheiten, dunkelgrün)

## 2025-01-09 00:15
- Refactoring: Ressourcen-Dateien in korrekte Ordnerstruktur verschoben
  - Verschoben: LargeRock.gd und LargeBush.gd nach scripts/resources/
  - Verschoben: LargeRock.tscn und LargeBush.tscn nach scenes/resources/
  - Aktualisiert: Pfade in allen betroffenen Dateien
  - Verbessert: Konsistente Projektstruktur für Ressourcen

## 2025-01-09 00:20
- Behoben: Signal-Probleme in großen Ressourcen
  - Ersetzt: Ungenutztes "resource_gathered" Signal durch "resource_removed"
  - Hinzugefügt: Korrekte Signal-Emission beim Ressourcenabbau
  - Angepasst: Signatur des Signals an bestehende Ressourcen angepasst
  - Verbessert: Konsistentes Verhalten mit normalen Ressourcen

## 2025-01-09 00:25
- Behoben: Ressourcen-Szenen Ladeprobleme
  - Korrigiert: Formatierung der .tscn Dateien
  - Vereinfacht: Resource IDs und Referenzen
  - Entfernt: Überflüssige Kommentare und UIDs
  - Verbessert: Kompatibilität mit Godot's Ressourcen-Loader

## 2024-01-09
- Mobile Navigation hinzugefügt
  - Neue Szene `MobileNavigation.tscn` erstellt mit einer unteren Navigationsleiste
  - "Bauen"-Button implementiert, der das Baumenü ein-/ausblendet
  - Anpassung für mobile Bildschirmformate

## 2025-01-09 00:19
- Added Fuel Display to HUD
- Added fuel resource display to ResourceHUD
- Updated ResourceHUD scene with fuel label
- Connected fuel display to resource management system

## 2025-01-09 00:25
- Behoben: Förster-Gebäude verschwindet nicht mehr beim Platzieren
  - Hinzugefügt: StaticBody3D-Komponente für korrekte Kollision
  - Angepasst: Kollisionsform an Gebäudegröße
  - Optimiert: Korrekte Positionierung auf der Planetenoberfläche
  - Verbessert: Konsistenz mit anderen Gebäuden

## 2025-01-09 00:30
- Behoben: Korrekte Gebäudeplatzierung auf der Planetenoberfläche
  - Korrigiert: Positionierung der Gebäude im BuildingManager
  - Entfernt: Manuelle Positions-Überschreibungen in Gebäuden
  - Verbessert: Konsistente Ausrichtung zur Planetenmitte
  - Optimiert: Platzierungslogik für sphärische Oberfläche

## 2025-01-09 00:35
- Implementiert: Intuitive Kamerasteuerung für Planetenrotation
  - Hinzugefügt: Kamerablickrelative Rotation des Planeten
  - Implementiert: Zoom-Funktion mit Mausrad und Pinch-Geste
  - Optimiert: Flüssige Kamerabewegungen ohne Pole
  - Angepasst: Zoom-Grenzen für optimale Übersicht
  - Verbessert: Touch- und Maussteuerung für alle Plattformen

## 2025-01-09 00:40
- Verbessert: Kamerarotation um Planetenzentrum
  - Korrigiert: Rotation erfolgt nun exakt um den Planetenmittelpunkt
  - Implementiert: Kamerabasiertes Rotationssystem statt Planetenrotation
  - Optimiert: Flüssigere Kamerabewegungen durch direkte Transformationen
  - Verbessert: Präzisere Steuerung der Kameraposition
  - Hinzugefügt: Speicherung der Kamerarotation für konsistente Bewegungen

## 2025-01-09 00:45
- Implementiert: Vollständig kamerarelative Rotation
  - Verbessert: Rotation folgt exakt der Kameraansicht
  - Entfernt: Abhängigkeit von Weltachsen
  - Optimiert: Direkte Transformation der Kameraposition
  - Hinzugefügt: Automatische Distanzkorrektur
  - Verbessert: Intuitivere Steuerung ohne "Pole"

## 2025-01-09
- Verbessert: Vollständig kamerarelative Rotation implementiert
  - Hinzugefügt: Rotation basiert nun auf der aktuellen Kameraausrichtung
  - Optimiert: Intuitivere Steuerung für horizontale und vertikale Bewegungen
  - Implementiert: Schutz vor extremen Rotationswinkeln
  - Verbessert: Natürlichere Bewegung bei der Planetenerkundung
