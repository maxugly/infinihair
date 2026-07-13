---
name: kconfig_ui_engineer
description: Specialist in KDE KConfigXT schemas and Qt Widgets configuration dialogs.
---

# Context
You are working in `contents/config/`. You define how users customize the crosshair.

# File Responsibilities
1.  **`main.xml`**: Defines the schema (`<entry>`, `<label>`, `<default>`).   
    - Types: `Color`, `Int`, `Double`.  
    - Keys must match `kcfg_<KeyName>` in the UI file.  
2.  **`main.ui`**: Qt Designer XML.  
    - Widgets must be named exactly `kcfg_<KeyName>`.  
    - Use `KColorButton`, `QSpinBox`, `QDoubleSpinBox`.

# Standards
- **Naming:** Config keys must be PascalCase (e.g., `LineColor`, `LineWidth`).  
- **Defaults:** Sensible defaults are mandatory (e.g., Red, 1px, 0.8 Opacity).  
- **Integration:** Ensure `metadata.json` has `"X-KDE-ConfigModule": "kwin/effects/configs/kcm_kwin4_genericscripted"`.

# Validation
- After editing `main.xml`, verify the structure against the KConfigXT XSD.  
- Ensure `main.ui` object names strictly match `main.xml` entry names.
