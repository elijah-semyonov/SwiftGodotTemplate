# SwiftGodotTemplate

This is a ready to use SwiftGodot project with an integrated SPM project and a small plugin to make your life a bit more convenient.

It provides a Editor tab with a button that allows you to rebuild shipped SwiftGodot SPM project in one tap and reload the editor after.

### Manully tested and supported on
Godot v4.4.1.stable.official [49a5bc7b6]

- macOS(M-family CPU)
    - Swift toolchain from Xcode Version 16.3 (16E140)
- Windows (x86_64)
    - after https://github.com/migueldeicaza/SwiftGodot/pull/689 is merged, or set dependency to `.package(url: "https://github.com/elijah-semyonov/SwiftGodot", branch: "typed-array")` in `swift_godot_game/Package.swift`
    - [Swift 6.1](https://www.swift.org/install/windows/)

### How to use it
1. Clone this repository
2. Open Godot project in the root
3. Open `SwiftGodot` tab on top (Screenshot 1)
3. Click `Recompile Swift` (Screenshot 2)

<img src="readme_resources/screenshot.png" width="600">

Wait. 

The script will build the project and copy the built libraries to location set by `swift_godot.gdextension`.

When build is finished Godot editor will reopen the current project.

### Windows only
After the first build on Windows you need to copy some Swift runtime `dll`s into `res://addons/swift_godot_extension/bin/x86_64-unknown-windows-msvc/debug/` and reload project.

They are located nearby the Swift toolchain location. Use PowerShell to find it
```
Get-Command swift
```
The path similar to `AppData\Local\Programs\Swift\Runtimes\6.1.0\usr\bin` is where to look.

More info in [SwiftGodot Documentation](https://migueldeicaza.github.io/SwiftGodotDocs/documentation/swiftgodot/windows)

### How does it work
Godot Editor plugin sitting in `res://addons/swift_godot_editor_plugin` simply runs `swift build` command using [OS.create_process](https://docs.godotengine.org/en/stable/classes/class_os.html#class-os-method-create-process) with `--build-path` set to folder where `swift_godot.gdextension` expects it

### Where is SwiftGodot project?
Swift Package Manager (SPM) project dependent on `SwiftGodot` sits in `swift_godot_game` directory. It's invisible to Godot project due to `.gdignore` file in there. You can work with it in any IDE that can work with SPM and use the Editor plugin functionality to rebuild it.

### Demo
[![Demo video](https://img.youtube.com/vi/f1JM4jtfrdY/0.jpg)](https://www.youtube.com/watch?v=f1JM4jtfrdY)
