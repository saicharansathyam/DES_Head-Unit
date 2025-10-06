# DES Head-Unit

Qt6 application targeting a custom Linux image built with Yocto (in Docker).

## Repository Structure

```
src/         # Qt6 Application source code
yocto/       # Yocto recipes, layers, and config
docker/      # Dockerfiles for Yocto builds
scripts/     # Build, test, and integration scripts
.github/
  workflows/ # GitHub Actions CI/CD workflows
CMakeLists.txt
README.md
```

## Build & Development

- Qt6 app builds on Ubuntu and Windows (locally).
- CI/CD (GitHub Actions) builds, tests, and packages on Ubuntu, targeting Yocto/Docker.

## Getting Started

Populate each folder with your project-specific code and configuration!
