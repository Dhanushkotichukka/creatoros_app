allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir("../build"))

subprojects {
    project.evaluationDependsOn(":app")
    project.layout.buildDirectory.value(rootProject.layout.buildDirectory.dir(project.name))
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
