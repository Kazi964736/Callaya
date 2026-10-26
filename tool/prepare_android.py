"""Run after `flutter create --platforms android .` to finish the Android setup.

flutter_local_notifications needs Java 8+ API "desugaring" switched on in the
app's Gradle file. This script adds it to build.gradle.kts or build.gradle,
whichever `flutter create` generated, and is safe to run more than once.
"""
import pathlib
import re
import sys

DESUGAR = "com.android.tools:desugar_jdk_libs:2.1.4"
app = pathlib.Path(__file__).resolve().parent.parent / "android" / "app"
kts = app / "build.gradle.kts"
groovy = app / "build.gradle"

if kts.exists():
    path, flag, dep = kts, "isCoreLibraryDesugaringEnabled = true", f'coreLibraryDesugaring("{DESUGAR}")'
elif groovy.exists():
    path, flag, dep = groovy, "coreLibraryDesugaringEnabled true", f"coreLibraryDesugaring '{DESUGAR}'"
else:
    sys.exit("No android/app/build.gradle(.kts) found. Run `flutter create --platforms android .` first.")

text = path.read_text()

if "CoreLibraryDesugaringEnabled" not in text and "coreLibraryDesugaringEnabled" not in text:
    text, n = re.subn(r"compileOptions\s*\{", "compileOptions {\n        " + flag, text, count=1)
    if n == 0:
        text = re.sub(
            r"android\s*\{",
            "android {\n    compileOptions {\n        " + flag + "\n    }",
            text,
            count=1,
        )

if "desugar_jdk_libs" not in text:
    text += "\ndependencies {\n    " + dep + "\n}\n"

path.write_text(text)
print(f"Desugaring enabled in {path.relative_to(app.parent.parent)}")
