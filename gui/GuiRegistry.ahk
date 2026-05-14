#Requires AutoHotkey v2.0

class GuiRegistry {
    static _builders := Map()
    static _instances := Map()

    static Define(name, buildFn) {
        this._builders[name] := buildFn
    }

    static Ensure(name) {
        if (this._instances.Has(name) && IsObject(this._instances[name])) {
            return this._instances[name]
        }
        if !this._builders.Has(name) {
            throw Error("GuiRegistry builder not defined: " name)
        }
        guiObj := this._builders[name].Call()
        if !IsObject(guiObj) {
            throw Error("GuiRegistry builder returned invalid gui: " name)
        }
        this._instances[name] := guiObj
        return guiObj
    }

    static IsBuilt(name) {
        return this._instances.Has(name) && IsObject(this._instances[name])
    }

    static HideIfBuilt(name) {
        if this.IsBuilt(name) {
            this._instances[name].Hide()
        }
    }
}
