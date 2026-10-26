# The on-device ML Kit text recognizer used by Dompetektif bundles the Latin
# model only. The plugin still references optional Chinese, Devanagari,
# Japanese, and Korean recognizers at runtime, so R8 must not fail on those
# intentionally absent classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit discovers its ComponentRegistrar implementations by class name (from
# the merged manifest) and instantiates them reflectively through their no-arg
# constructor. R8 full mode keeps the manifest-referenced class names but strips
# the unreferenced <init>(), leaving the ML Kit component registry empty. The
# symptom is a crash on every scan in release builds only:
#   NullPointerException: Attempt to invoke virtual method
#   'java.lang.Class java.lang.Object.getClass()' on a null object reference
# https://github.com/googlesamples/mlkit/issues/1001
-keep class * implements com.google.firebase.components.ComponentRegistrar { <init>(); }
-keep class com.google.mlkit.**Registrar { <init>(); }
