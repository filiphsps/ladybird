add_library(ladybird_swift STATIC
    Interface/_LadybirdSwiftPlaceholder.swift
)
set_target_properties(ladybird_swift PROPERTIES
    Swift_MODULE_NAME "LadybirdSwift"
)
target_compile_options(ladybird_swift PRIVATE
    "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-emit-objc-header-path ${CMAKE_CURRENT_BINARY_DIR}/LadybirdSwift.h>"
)
target_include_directories(ladybird_swift PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>)

# Register the bridging header as an additional output of compiling one of the
# Swift sources, so Ninja knows which rule produces it. Without this, Obj-C++
# sources that #import it fail with a missing-rule error on a cold build.
set_source_files_properties(
    Interface/_LadybirdSwiftPlaceholder.swift
    PROPERTIES
    OBJECT_OUTPUTS "${CMAKE_CURRENT_BINARY_DIR}/LadybirdSwift.h"
)

add_library(ladybird_impl STATIC
    Application/Application.mm
    Application/ApplicationDelegate.mm
    Application/EventLoopImplementationMacOS.mm
    Interface/Autocomplete.mm
    Interface/BookmarkFolder.mm
    Interface/BookmarksBar.mm
    Interface/Event.mm
    Interface/InfoBar.mm
    Interface/LadybirdWebView.mm
    Interface/LadybirdWebViewBridge.cpp
    Interface/LadybirdWebViewWindow.mm
    Interface/Menu.mm
    Interface/Palette.mm
    Interface/SearchPanel.mm
    Interface/Tab.mm
    Interface/TabController.mm
    Utilities/Conversions.mm
)
target_include_directories(ladybird_impl PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>)
target_link_libraries(ladybird_impl PUBLIC ladybird_swift)

# ladybird_impl Obj-C++ sources that #import "LadybirdSwift.h" require
# the bridging header to exist before they compile. Force the entire Swift
# target to build first so ordering is bulletproof regardless of which .mm
# files happen to import it.
add_dependencies(ladybird_impl ladybird_swift)

target_compile_options(ladybird_impl PUBLIC
    $<$<COMPILE_LANGUAGE:CXX>:-fobjc-arc>
    $<$<COMPILE_LANGUAGE:CXX>:-Wno-deprecated-anon-enum-enum-conversion> # Required for CGImageCreate
)
target_compile_features(ladybird_impl PUBLIC cxx_std_23)

add_executable(ladybird MACOSX_BUNDLE
    main.mm
)
target_link_libraries(ladybird_impl PUBLIC "-framework Cocoa -framework Metal -framework QuartzCore -framework UniformTypeIdentifiers" LibUnicode)
target_link_libraries(ladybird PRIVATE ladybird_impl)

create_ladybird_bundle(ladybird)
