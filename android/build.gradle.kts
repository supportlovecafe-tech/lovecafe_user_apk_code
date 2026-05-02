allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Default build directory

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
