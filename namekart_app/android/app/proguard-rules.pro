# Keep Tink crypto classes
-keep class com.google.crypto.tink.** { *; }

# Keep Bouncy Castle
-keep class org.bouncycastle.** { *; }

# Keep Nimbus JOSE classes
-keep class com.nimbusds.** { *; }

# Keep FindBugs annotations (used by Microsoft Identity SDK)
-keep class edu.umd.cs.findbugs.annotations.** { *; }

# Avoid stripping key crypto and signing classes
-dontwarn com.google.crypto.tink.**
-dontwarn org.bouncycastle.**
-dontwarn com.nimbusds.**
-dontwarn edu.umd.cs.findbugs.annotations.**


# Microsoft Authentication Library (MSAL)
-keep class com.microsoft.identity.** { *; }
-dontwarn com.microsoft.identity.**


# AndroidX Lifecycle (sometimes required)
-keep class androidx.lifecycle.** { *; }

# Gson (used internally)
-keep class com.google.gson.** { *; }

