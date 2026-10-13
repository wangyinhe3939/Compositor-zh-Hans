#!/bin/zsh
# Builds the community release. Signing and packaging are separate release steps.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$PROJECT_DIR/.build_tmp"
mkdir -p "$WORK/tmp" "$WORK/ModuleCache"
export TMPDIR="$WORK/tmp"
export CLANG_MODULE_CACHE_PATH="$WORK/ModuleCache"
export SWIFT_MODULECACHE_PATH="$WORK/ModuleCache"

xcodebuild -quiet \
  -project "$PROJECT_DIR/Compositor.xcodeproj" \
  -scheme Compositor -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$WORK/DerivedData" \
  -clonedSourcePackagesDirPath "$WORK/SourcePackages" \
  -packageCachePath "$WORK/PackageCache" \
  -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM= \
  ENABLE_PREVIEWS=NO ENABLE_DEBUG_DYLIB=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  GCC_GENERATE_DEBUGGING_SYMBOLS=NO DEBUG_INFORMATION_FORMAT=dwarf \
  SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
  ENABLE_CODE_COVERAGE=NO CLANG_COVERAGE_MAPPING=NO \
  COPY_PHASE_STRIP=NO STRIP_INSTALLED_PRODUCT=YES \
  SWIFT_OPTIMIZATION_LEVEL=-O \
  OTHER_SWIFT_FLAGS="\$(inherited) -file-prefix-map \"$PROJECT_DIR=.\" -debug-prefix-map \"$PROJECT_DIR=.\"" \
  OTHER_CFLAGS="\$(inherited) -ffile-prefix-map=\"$PROJECT_DIR=.\"" \
  build
