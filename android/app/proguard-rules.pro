# The on-device ML Kit text recognizer used by Dompetektif bundles the Latin
# model only. The plugin still references optional Chinese, Devanagari,
# Japanese, and Korean recognizers at runtime, so R8 must not fail on those
# intentionally absent classes.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
