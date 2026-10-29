import com.android.build.api.artifact.SingleArtifact
import java.util.Properties
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.transform.TransformerFactory
import javax.xml.transform.dom.DOMSource
import javax.xml.transform.stream.StreamResult
import org.w3c.dom.Element

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing reads android/key.properties (gitignored; see README
// "Android release signing"). Without it, release builds fall back to the
// debug key so `flutter run --release` still works locally; `flutter build
// appbundle` fails instead, so a debug-signed bundle can't reach the store.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.productivemuslim.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications (java.time backport).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.productivemuslim.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!keystoreProperties.isEmpty) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug").also {
                    // An app bundle is only for store upload: never debug-sign one.
                    if (gradle.startParameter.taskNames.any { it.contains("bundle", ignoreCase = true) }) {
                        throw GradleException("android/key.properties not found: refusing to build a debug-signed app bundle")
                    }
                    logger.warn("android/key.properties not found: release build is debug-signed")
                }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

// Play fallback (README "Android release signing"):
// `ORG_GRADLE_PROJECT_focusBlocking=false flutter build appbundle` removes the
// app-blocking AccessibilityService from the merged manifest, leaving DND-only
// jamaat focus. The app asks the platform whether the service exists
// (JamaatFocus.blockingAvailable) and hides the lock / nafs-lock settings.
val focusBlocking = (findProperty("focusBlocking") as String?)?.toBoolean() ?: true

abstract class StripFocusServiceTask : DefaultTask() {
    @get:InputFile
    abstract val mergedManifest: RegularFileProperty

    @get:OutputFile
    abstract val updatedManifest: RegularFileProperty

    @TaskAction
    fun strip() {
        val androidNs = "http://schemas.android.com/apk/res/android"
        val doc = DocumentBuilderFactory.newInstance()
            .apply { isNamespaceAware = true }
            .newDocumentBuilder()
            .parse(mergedManifest.get().asFile)
        val services = doc.getElementsByTagName("service")
        val focus = (0 until services.length).map { services.item(it) as Element }
            .filter { it.getAttributeNS(androidNs, "name").endsWith(".JamaatFocusService") }
        // A rename must fail the build, not silently ship the service.
        check(focus.size == 1) { "JamaatFocusService not found in the merged manifest" }
        focus.forEach { it.parentNode.removeChild(it) }
        TransformerFactory.newInstance().newTransformer()
            .transform(DOMSource(doc), StreamResult(updatedManifest.get().asFile))
    }
}

androidComponents {
    onVariants { variant ->
        if (!focusBlocking) {
            val name = variant.name.replaceFirstChar { it.uppercase() }
            val strip = tasks.register<StripFocusServiceTask>("strip${name}FocusService")
            variant.artifacts.use(strip)
                .wiredWithFiles(
                    StripFocusServiceTask::mergedManifest,
                    StripFocusServiceTask::updatedManifest,
                )
                .toTransform(SingleArtifact.MERGED_MANIFEST)
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    testImplementation("junit:junit:4.13.2")
}
