/// How strongly artwork-derived palette colour tints the interface.
enum AmbienceIntensity { off, subtle, rich }

/// How much translucency floating surfaces (navigation, player chrome,
/// menus, dialogs) use. [off] renders them as solid surfaces, which is also
/// what weak TV hardware gets regardless of the setting.
enum GlassIntensity { off, subtle, full }
