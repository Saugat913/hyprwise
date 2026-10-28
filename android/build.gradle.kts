allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// subprojects {
//     if (project.path != ":app") {
//         project.evaluationDependsOn(":app")
//     }
// }

subprojects {
    if (project.name == "app" || project.path == ":app") {
        return@subprojects
    }

    val configureAndroid = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            val setCompileSdk = android.javaClass.methods.firstOrNull {
                it.name == "setCompileSdk" && it.parameterTypes.size == 1
            } ?: android.javaClass.methods.firstOrNull {
                it.name == "compileSdkVersion" && it.parameterTypes.size == 1
            }
            if (setCompileSdk != null) {
                val pt = setCompileSdk.parameterTypes[0]
                if (pt == java.lang.Integer::class.java || pt == Int::class.javaPrimitiveType) {
                    setCompileSdk.invoke(android, 36)
                } else if (pt == String::class.java) {
                    setCompileSdk.invoke(android, "android-36")
                }
            }
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                val setSource = compileOptions.javaClass.getMethod("setSourceCompatibility", Object::class.java)
                val setTarget = compileOptions.javaClass.getMethod("setTargetCompatibility", Object::class.java)
                setSource.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_17)
                setTarget.invoke(compileOptions, org.gradle.api.JavaVersion.VERSION_17)
            } catch (_: Throwable) {}
        }
    }

    if (project.state.executed) {
        configureAndroid()
    } else {
        project.afterEvaluate { configureAndroid() }
    }

    tasks.withType(JavaCompile::class.java).configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }

    tasks.matching { it.name.contains("Kotlin", ignoreCase = true) }.configureEach {
        try {
            val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
            val kotlinOptions = getKotlinOptions.invoke(this)
            val setLanguageVersion = kotlinOptions.javaClass.getMethod("setLanguageVersion", String::class.java)
            try {
                setLanguageVersion.invoke(kotlinOptions, "2.1")
            } catch (_: Throwable) {
                setLanguageVersion.invoke(kotlinOptions, "2.0")
            }
            try {
                val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
                setJvmTarget.invoke(kotlinOptions, "17")
            } catch (_: Throwable) {}
        } catch (_: Throwable) {}

        try {
            val getCompilerOptions = this.javaClass.getMethod("getCompilerOptions")
            val compilerOptions = getCompilerOptions.invoke(this)
            val getLanguageVersion = compilerOptions.javaClass.getMethod("getLanguageVersion")
            val prop = getLanguageVersion.invoke(compilerOptions) as org.gradle.api.provider.Property<*>
            val kotlinVersionEnum = Class.forName("org.jetbrains.kotlin.gradle.dsl.KotlinVersion")
            val targetKotlin = try {
                kotlinVersionEnum.getField("KOTLIN_2_1").get(null)
            } catch (_: Throwable) {
                kotlinVersionEnum.getField("KOTLIN_2_0").get(null)
            }
            val setMethod = prop.javaClass.getMethod("set", Object::class.java)
            setMethod.invoke(prop, targetKotlin)

            try {
                val getJvmTarget = compilerOptions.javaClass.getMethod("getJvmTarget")
                val jvmProp = getJvmTarget.invoke(compilerOptions) as org.gradle.api.provider.Property<*>
                val jvmTargetEnum = Class.forName("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                val jvm17 = jvmTargetEnum.getField("JVM_17").get(null)
                setMethod.invoke(jvmProp, jvm17)
            } catch (_: Throwable) {}
        } catch (_: Throwable) {}
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
