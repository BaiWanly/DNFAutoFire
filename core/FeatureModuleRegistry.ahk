#Requires AutoHotkey v2.0

class FeatureModuleRegistry {
    static FeatureOrder := ["LvRen", "GuanYu", "PetSkill", "JianZong", "AutoRun", "Combo", "ZhanFa"]

    static StartEnabledModules(presetName := unset) {
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }
        for featureName in this.EnabledFeatures(presetName) {
            this._PrepareFeature(featureName, presetName)
            MultipleThread.StartFeatureThread(featureName)
        }
    }

    static StopAllModules() {
        MultipleThread.StopAllThreads()
    }

    static AnyModuleRunning() {
        return MultipleThread.AnyThreadRunning()
    }

    static EnabledFeatures(presetName := unset) {
        if !IsSet(presetName) {
            presetName := SessionState.GetCurrentPreset()
        }
        enabled := []
        for featureName in this.FeatureOrder {
            if PresetExFeatures.IsOn(featureName, presetName) {
                enabled.Push(featureName)
            }
        }
        return enabled
    }

    static _PrepareFeature(featureName, presetName) {
        if (featureName = "JianZong") {
            skillKey := LoadPreset(presetName, "JianZongSkillKey")
            if (skillKey != "") {
                AutoFireController.UseBlockingOriginalKeyMode(skillKey)
            }
        }
    }
}
