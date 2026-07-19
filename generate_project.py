#!/usr/bin/env python3
"""Generate a valid project.pbxproj for the Bible App Xcode project."""
import uuid
import os

def uid():
    return uuid.uuid4().hex.upper()[:24]

PROJECT_DIR = os.path.dirname(os.path.abspath(__file__))
XCODEPROJ_DIR = os.path.join(PROJECT_DIR, "bible-app", "bible-app.xcodeproj")

# Core file system references
# Each file in the project needs a PBXFileReference, and each source file needs a PBXBuildFile

# File references
refs = {}

def add_ref(path, name, last_known_file_type=None, explicit_type=None):
    ref_id = uid()
    entry = {
        "isa": "PBXFileReference",
        "isaOrder": ["explicitFileType", "includeInIndex", "path", "sourceTree", "lastKnownFileType", "name", "fileEncoding"],
        "explicitFileType": explicit_type,
        "includeInIndex": "0",
        "path": path,
        "sourceTree": "<group>",
        "lastKnownFileType": last_known_file_type,
        "name": name,
        "fileEncoding": "4",
    }
    refs[ref_id] = entry
    return ref_id

# Build files
build_files = {}

def add_build_file(file_ref_id, settings=None):
    bf_id = uid()
    entry = {
        "isa": "PBXBuildFile",
        "isaOrder": ["fileRef"],
        "fileRef": file_ref_id,
    }
    if settings:
        entry["settings"] = settings
    build_files[bf_id] = entry
    return bf_id, entry

# Groups
groups = {}

def add_group(name, path=None, children=None, source_tree="<group>"):
    gid = uid()
    entry = {
        "isa": "PBXGroup",
        "isaOrder": ["children", "path", "name", "sourceTree"],
        "children": children or [],
        "path": path,
        "name": name,
        "sourceTree": source_tree,
    }
    groups[gid] = entry
    return gid

# Build phases
sources_build_phase_id = uid()
resources_build_phase_id = uid()
frameworks_build_phase_id = uid()

sources_build_phase = {
    "isa": "PBXSourcesBuildPhase",
    "isaOrder": ["buildActionMask", "files", "runOnlyForDeploymentPostprocessing"],
    "buildActionMask": "2147483647",
    "files": [],
    "runOnlyForDeploymentPostprocessing": "0",
}

resources_build_phase = {
    "isa": "PBXResourcesBuildPhase",
    "isaOrder": ["buildActionMask", "files", "runOnlyForDeploymentPostprocessing"],
    "buildActionMask": "2147483647",
    "files": [],
    "runOnlyForDeploymentPostprocessing": "0",
}

frameworks_build_phase = {
    "isa": "PBXFrameworksBuildPhase",
    "isaOrder": ["buildActionMask", "files", "runOnlyForDeploymentPostprocessing"],
    "buildActionMask": "2147483647",
    "files": [],
    "runOnlyForDeploymentPostprocessing": "0",
}

# --- Register files ---

# Source files
bible_app_ref = add_ref("Sources/App/BibleApp.swift", "BibleApp.swift", last_known_file_type="sourcecode.swift")
content_view_ref = add_ref("Sources/Views/ContentView.swift", "ContentView.swift", last_known_file_type="sourcecode.swift")

# Resources
assets_ref = add_ref("Resources/Assets.xcassets", None, explicit_type="folder.assetcatalog")
info_plist_ref = add_ref("Resources/Info.plist", "Info.plist", last_known_file_type="text.plist.xml")

# Build files for sources
bible_app_bf, _ = add_build_file(bible_app_ref)
content_view_bf, _ = add_build_file(content_view_ref)

# Build files for resources
assets_bf, _ = add_build_file(assets_ref)

# Add to phases
sources_build_phase["files"] = [bible_app_bf, content_view_bf]
resources_build_phase["files"] = [assets_bf]

# --- Create groups ---
root_group_id = add_group("bible-app", path="", children=[])
sources_group_id = add_group("Sources", path="Sources")
app_group_id = add_group("App", path="Sources/App", children=[bible_app_ref])
views_group_id = add_group("Views", path="Sources/Views", children=[content_view_ref])
resources_group_id = add_group("Resources", path="Resources", children=[assets_ref, info_plist_ref])

# Wire up the group hierarchy
sources_group_children = [app_group_id, views_group_id]
groups[sources_group_id]["children"] = sources_group_children

root_group_children = [sources_group_id, resources_group_id]
groups[root_group_id]["children"] = root_group_children

# --- Target ---
target_id = uid()
product_ref = add_ref("Bible App.app", "Bible App.app", explicit_type="wrapper.application")
product_ref_clean = product_ref

target = {
    "isa": "PBXNativeTarget",
    "isaOrder": ["buildConfigurationList", "buildPhases", "buildRules", "dependencies", "name", "productName", "productReference", "productType"],
    "buildConfigurationList": uid(),
    "buildPhases": [sources_build_phase_id, frameworks_build_phase_id, resources_build_phase_id],
    "buildRules": [],
    "dependencies": [],
    "name": "bible-app",
    "productName": "bible-app",
    "productReference": product_ref_clean,
    "productType": '"com.apple.product-type.application"',
}

# --- Build configurations ---
debug_config_id = uid()
release_config_id = uid()

debug_config = {
    "isa": "XCBuildConfiguration",
    "isaOrder": ["buildSettings", "name"],
    "buildSettings": {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_FILE": "Resources/Info.plist",
        "INFOPLIST_KEY_CFBundleDisplayName": "Bible App",
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "(UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight)",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "(UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight)",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/Frameworks")',
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.epaphroditus.bible",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": '"1,2"',
    },
    "name": "Debug",
}

release_config = {
    "isa": "XCBuildConfiguration",
    "isaOrder": ["buildSettings", "name"],
    "buildSettings": {
        "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
        "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
        "CODE_SIGN_STYLE": "Automatic",
        "CURRENT_PROJECT_VERSION": "1",
        "ENABLE_PREVIEWS": "YES",
        "GENERATE_INFOPLIST_FILE": "YES",
        "INFOPLIST_FILE": "Resources/Info.plist",
        "INFOPLIST_KEY_CFBundleDisplayName": "Bible App",
        "INFOPLIST_KEY_UIApplicationSceneManifest_Generation": "YES",
        "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
        "INFOPLIST_KEY_UILaunchScreen_Generation": "YES",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad": "(UIInterfaceOrientationPortrait, UIInterfaceOrientationPortraitUpsideDown, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight)",
        "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone": "(UIInterfaceOrientationPortrait, UIInterfaceOrientationLandscapeLeft, UIInterfaceOrientationLandscapeRight)",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "LD_RUNPATH_SEARCH_PATHS": '("$(inherited)", "@executable_path/Frameworks")',
        "MARKETING_VERSION": "1.0",
        "PRODUCT_BUNDLE_IDENTIFIER": "com.epaphroditus.bible",
        "PRODUCT_NAME": "$(TARGET_NAME)",
        "SWIFT_EMIT_LOC_STRINGS": "YES",
        "SWIFT_VERSION": "5.0",
        "TARGETED_DEVICE_FAMILY": '"1,2"',
    },
    "name": "Release",
}

# Target config list
target_config_list_id = target["buildConfigurationList"]
target_config_list = {
    "isa": "XCConfigurationList",
    "isaOrder": ["buildConfigurations", "defaultConfigurationIsVisible", "defaultConfigurationName"],
    "buildConfigurations": [debug_config_id, release_config_id],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release",
}

# Project config list
project_config_list_id = uid()
project_config_list = {
    "isa": "XCConfigurationList",
    "isaOrder": ["buildConfigurations", "defaultConfigurationIsVisible", "defaultConfigurationName"],
    "buildConfigurations": [
        uid(),
        uid(),
    ],
    "defaultConfigurationIsVisible": "0",
    "defaultConfigurationName": "Release",
}

# Project-level build configs (Debug/Release)
project_debug_config_id = project_config_list["buildConfigurations"][0]
project_release_config_id = project_config_list["buildConfigurations"][1]

project_debug_config = {
    "isa": "XCBuildConfiguration",
    "isaOrder": ["buildSettings", "name"],
    "buildSettings": {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "ENABLE_TESTABILITY": "YES",
        "GCC_DYNAMIC_NO_PIC": "NO",
        "GCC_OPTIMIZATION_LEVEL": "0",
        "GCC_PREPROCESSOR_DEFINITIONS": '"DEBUG=1"',
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "MTL_ENABLE_DEBUG_INFO": "INCLUDE_SOURCE",
        "ONLY_ACTIVE_ARCH": "YES",
        "SDKROOT": "iphoneos",
        "SWIFT_ACTIVE_COMPILATION_CONDITIONS": "DEBUG",
        "SWIFT_OPTIMIZATION_LEVEL": '"-Onone"',
    },
    "name": "Debug",
}

project_release_config = {
    "isa": "XCBuildConfiguration",
    "isaOrder": ["buildSettings", "name"],
    "buildSettings": {
        "ALWAYS_SEARCH_USER_PATHS": "NO",
        "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
        "CLANG_ANALYZER_NONNULL": "YES",
        "CLANG_CXX_LANGUAGE_STANDARD": "gnu++20",
        "CLANG_ENABLE_MODULES": "YES",
        "CLANG_ENABLE_OBJC_ARC": "YES",
        "COPY_PHASE_STRIP": "NO",
        "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
        "ENABLE_NS_ASSERTIONS": "NO",
        "ENABLE_STRICT_OBJC_MSGSEND": "YES",
        "GCC_OPTIMIZATION_LEVEL": "s",
        "IPHONEOS_DEPLOYMENT_TARGET": "17.0",
        "MTL_ENABLE_DEBUG_INFO": "NO",
        "SDKROOT": "iphoneos",
        "SWIFT_COMPILATION_MODE": "wholemodule",
        "SWIFT_OPTIMIZATION_LEVEL": '"-O"',
        "VALIDATE_PRODUCT": "YES",
    },
    "name": "Release",
}

# --- PBXProject ---
main_group_id = root_group_id
project_id = uid()
project_obj = {
    "isa": "PBXProject",
    "isaOrder": ["attributes", "buildConfigurationList", "compatibilityVersion", "developmentRegion", "hasScannedForEncodings", "knownRegions", "mainGroup", "productRefGroup", "projectDirPath", "projectRoot", "targets"],
    "attributes": {
        "BuildIndependentTargetsInParallel": "1",
        "LastSwiftUpdateCheck": "1500",
        "LastUpgradeCheck": "1500",
        "TargetAttributes": {
            target_id: {
                "CreatedOnToolsVersion": "15.0",
            }
        }
    },
    "buildConfigurationList": project_config_list_id,
    "compatibilityVersion": "Xcode 14.0",
    "developmentRegion": "en",
    "hasScannedForEncodings": "0",
    "knownRegions": ["en", "Base"],
    "mainGroup": main_group_id,
    "productRefGroup": root_group_id,
    "projectDirPath": '""',
    "projectRoot": '""',
    "targets": [target_id],
}

# Collect all objects
all_objects = {}

def safe_add(d, obj_id, obj):
    """Add to all_objects, filtering out None values"""
    cleaned = {}
    isa_order = obj.get("isaOrder", [])
    for key in isa_order:
        if key in obj and obj[key] is not None:
            cleaned[key] = obj[key]
    # Add remaining keys not in isa_order
    for key, val in obj.items():
        if key == "isaOrder" or key in isa_order:
            continue
        if val is not None:
            cleaned[key] = val
    d[obj_id] = cleaned

safe_add(all_objects, bible_app_ref, refs[bible_app_ref])
safe_add(all_objects, content_view_ref, refs[content_view_ref])
safe_add(all_objects, assets_ref, refs[assets_ref])
safe_add(all_objects, info_plist_ref, refs[info_plist_ref])
safe_add(all_objects, product_ref_clean, refs[product_ref_clean])

safe_add(all_objects, bible_app_bf, build_files[bible_app_bf])
safe_add(all_objects, content_view_bf, build_files[content_view_bf])
safe_add(all_objects, assets_bf, build_files[assets_bf])

safe_add(all_objects, sources_build_phase_id, sources_build_phase)
safe_add(all_objects, resources_build_phase_id, resources_build_phase)
safe_add(all_objects, frameworks_build_phase_id, frameworks_build_phase)

safe_add(all_objects, root_group_id, groups[root_group_id])
safe_add(all_objects, sources_group_id, groups[sources_group_id])
safe_add(all_objects, app_group_id, groups[app_group_id])
safe_add(all_objects, views_group_id, groups[views_group_id])
safe_add(all_objects, resources_group_id, groups[resources_group_id])

safe_add(all_objects, target_id, target)
safe_add(all_objects, debug_config_id, debug_config)
safe_add(all_objects, release_config_id, release_config)
safe_add(all_objects, target_config_list_id, target_config_list)
safe_add(all_objects, project_config_list_id, project_config_list)
safe_add(all_objects, project_debug_config_id, project_debug_config)
safe_add(all_objects, project_release_config_id, project_release_config)
safe_add(all_objects, project_id, project_obj)


def serialize_value(val, indent=0):
    """Serialize a value in old-style ASCII plist format."""
    indent_str = "\t" * indent
    inner_indent = "\t" * (indent + 1)
    
    if isinstance(val, dict):
        # Remove isaOrder from serialization
        isa_order = val.pop("isaOrder", [])
        ordered_keys = isa_order + [k for k in sorted(val.keys()) if k not in isa_order]
        items = []
        for k in ordered_keys:
            if k in val:
                v = serialize_value(val[k], indent + 1)
                items.append(f"{inner_indent}{k} = {v};")
        # Put isaOrder back as a hidden marker (not serialized)
        val["isaOrder"] = isa_order
        return "{\n" + "\n".join(items) + f"\n{indent_str}}}"
    elif isinstance(val, list):
        if not val:
            return "()"
        items = [f"{inner_indent}{serialize_value(v, indent + 1)}," for v in val]
        return "(\n" + "\n".join(items) + f"\n{indent_str})"
    elif isinstance(val, str):
        if val.startswith('"') and val.endswith('"'):
            # Already quoted (like the device family string)
            return val
        if any(c in val for c in ' {}()[]=;,\n\t"'):
            return f'"{val}"'
        return val
    elif isinstance(val, bool):
        return "YES" if val else "NO"
    elif val is None:
        return ""
    return str(val)


def format_pbxproj(objects):
    """Format the entire pbxproj content."""
    lines = [
        "// !$*UTF8*$!",
        "{",
        "\tarchiveVersion = 1;",
        "\tclasses = {",
        "\t};",
        "\tobjectVersion = 56;",
        "\tobjects = {",
        "",
    ]
    
    # Group by ISA
    by_isa = {}
    for oid, obj in objects.items():
        isa = obj.get("isa", "Unknown")
        by_isa.setdefault(isa, {})[oid] = obj
    
    # Sort ISAs for consistent output
    isa_order = [
        "PBXBuildFile",
        "PBXFileReference",
        "PBXFrameworksBuildPhase",
        "PBXGroup",
        "PBXNativeTarget",
        "PBXProject",
        "PBXResourcesBuildPhase",
        "PBXSourcesBuildPhase",
        "XCBuildConfiguration",
        "XCConfigurationList",
    ]
    
    for isa_name in isa_order:
        if isa_name not in by_isa:
            continue
        isa_objects = by_isa[isa_name]
        lines.append(f"/* Begin {isa_name} section */")
        for oid in sorted(isa_objects.keys()):
            obj = isa_objects[oid]
            serialized = serialize_value(obj, 2)
            lines.append(f"\t\t{oid} = {serialized};")
        lines.append(f"/* End {isa_name} section */")
        lines.append("")
    
    lines.append("\t};")
    lines.append("\trootObject = " + project_id + ";")
    lines.append("}")
    
    return "\n".join(lines)


pbxproj_content = format_pbxproj(all_objects)

output_path = os.path.join(XCODEPROJ_DIR, "project.pbxproj")
with open(output_path, "w") as f:
    f.write(pbxproj_content)

print(f"Generated: {output_path}")
print(f"Size: {len(pbxproj_content)} bytes")
