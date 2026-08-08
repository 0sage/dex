# Homebrew cask for Dex. This repository doubles as its own tap:
#
#   brew tap 0sage/dex https://github.com/0sage/dex.git
#   brew install --cask dex
#
# `version` and `sha256` are rewritten by .github/workflows/release.yml on every
# tagged build, so this file always points at the latest release.
cask "dex" do
  version "1.126.0"
  sha256 "0cefe4844ffad4ed952335753b595cc5681ca7bca4de204aff62720f2c24881d"

  url "https://github.com/0sage/dex/releases/download/v#{version}/Dex-darwin-arm64-#{version}.zip"
  name "Dex"
  desc "Code editor: files left, editor centre, terminal right"
  homepage "https://github.com/0sage/dex"

  depends_on macos: :big_sur
  depends_on arch: :arm64

  # The binary is the CLI shipped inside the bundle, so `dex .` works from a
  # terminal. It is named after product.json's applicationName, set to `dex`.
  app "Dex.app"
  binary "#{appdir}/Dex.app/Contents/Resources/app/bin/dex"

  # Dex is ad-hoc signed, not notarized, so Gatekeeper rejects it while the
  # quarantine flag is set. Homebrew 6 removed `--no-quarantine`, and the flag
  # cannot be cleared once the app is in /Applications: macOS 15 requires App
  # Management permission to modify a bundle there, so xattr fails with EPERM.
  # preflight runs while the app is still in Homebrew's staging directory, where
  # clearing it does work.
  preflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{staged_path}/Dex.app"]
  end

  # Finder integration: an Automator "Quick Action" that opens the selected
  # files or folders in Dex, the same mechanism Cursor and Zed use.
  #
  # This is written at install time rather than shipped inside Dex.app because a
  # service bundled in the app would only be picked up from /Applications, and
  # macOS caches Services per-user — the flush below is what makes the entry
  # appear without a logout.
  #
  # Top-level placement (where Terminal puts "New Terminal at Folder") is not
  # available to us: the only public API for that is a FIFinderSync extension,
  # which macOS refuses to load unless it is notarized. Dex is ad-hoc signed, so
  # Quick Actions and the Services menu are as far up as it can go.
  #
  # service_name is the menu label and also half of the NSServicesStatus
  # preferences key, so the two have to agree — keep it in one place.
  service_name = "Open in Dex"
  service_path = "#{Dir.home}/Library/Services/#{service_name}.workflow"

  postflight do
    require "fileutils"

    FileUtils.mkdir_p "#{service_path}/Contents/Resources"

    # The menu item's icon. Without this NSIconName falls back to
    # NSActionTemplate, the generic Automator badge — which is why Zed's entry
    # looks anonymous. Copying Dex's own .icns in and naming it
    # workflowCustomImage is what Hyper does, and it is the name Automator itself
    # writes when you set a custom image on a service.
    FileUtils.cp "#{appdir}/Dex.app/Contents/Resources/Dex.icns",
                 "#{service_path}/Contents/Resources/workflowCustomImage.icns"

    File.write "#{service_path}/Contents/Info.plist", <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      \t<key>NSServices</key>
      \t<array>
      \t\t<dict>
      \t\t\t<key>NSBackgroundColorName</key><string>background</string>
      \t\t\t<key>NSIconName</key><string>workflowCustomImage</string>
      \t\t\t<key>NSMenuItem</key>
      \t\t\t<dict><key>default</key><string>#{service_name}</string></dict>
      \t\t\t<key>NSMessage</key><string>runWorkflowAsService</string>
      \t\t\t<key>NSRequiredContext</key>
      \t\t\t<dict><key>NSApplicationIdentifier</key><string>com.apple.finder</string></dict>
      \t\t\t<key>NSSendFileTypes</key>
      \t\t\t<array><string>public.item</string></array>
      \t\t</dict>
      \t</array>
      </dict>
      </plist>
    PLIST

    # A single stock "Open Finder Items" action pointed at Dex.app. The UUIDs are
    # arbitrary but must be present and internally consistent, and connectors is
    # empty because there is only one action in the chain.
    File.write "#{service_path}/Contents/document.wflow", <<~WFLOW
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      \t<key>AMApplicationBuild</key><string>533</string>
      \t<key>AMApplicationVersion</key><string>2.10</string>
      \t<key>AMDocumentVersion</key><string>2</string>
      \t<key>actions</key>
      \t<array>
      \t\t<dict>
      \t\t\t<key>action</key>
      \t\t\t<dict>
      \t\t\t\t<key>AMAccepts</key>
      \t\t\t\t<dict>
      \t\t\t\t\t<key>Container</key><string>List</string>
      \t\t\t\t\t<key>Optional</key><false/>
      \t\t\t\t\t<key>Types</key>
      \t\t\t\t\t<array><string>com.apple.cocoa.path</string></array>
      \t\t\t\t</dict>
      \t\t\t\t<key>AMActionVersion</key><string>1.1.1</string>
      \t\t\t\t<key>AMApplication</key>
      \t\t\t\t<array><string>Finder</string></array>
      \t\t\t\t<key>AMParameterProperties</key>
      \t\t\t\t<dict>
      \t\t\t\t\t<key>appPath</key>
      \t\t\t\t\t<dict>
      \t\t\t\t\t\t<key>isPathPopUp</key><true/>
      \t\t\t\t\t\t<key>variableUUIDsInMenu</key><array/>
      \t\t\t\t\t</dict>
      \t\t\t\t</dict>
      \t\t\t\t<key>AMProvides</key>
      \t\t\t\t<dict>
      \t\t\t\t\t<key>Container</key><string>List</string>
      \t\t\t\t\t<key>Types</key>
      \t\t\t\t\t<array><string>com.apple.cocoa.path</string></array>
      \t\t\t\t</dict>
      \t\t\t\t<key>ActionBundlePath</key>
      \t\t\t\t<string>/System/Library/Automator/Open Finder Items.action</string>
      \t\t\t\t<key>ActionName</key><string>Open Finder Items</string>
      \t\t\t\t<key>ActionParameters</key>
      \t\t\t\t<dict><key>appPath</key><string>#{appdir}/Dex.app</string></dict>
      \t\t\t\t<key>BundleIdentifier</key>
      \t\t\t\t<string>com.apple.Automator.OpenFinderItems</string>
      \t\t\t\t<key>CFBundleVersion</key><string>1.1.1</string>
      \t\t\t\t<key>CanShowSelectedItemsWhenRun</key><true/>
      \t\t\t\t<key>CanShowWhenRun</key><true/>
      \t\t\t\t<key>Category</key>
      \t\t\t\t<array><string>AMCategoryFilesAndFolders</string></array>
      \t\t\t\t<key>Class Name</key><string>AMOpenFinderItems</string>
      \t\t\t\t<key>InputUUID</key><string>6D1F2A3B-4C5D-6E7F-8A9B-0C1D2E3F4A5B</string>
      \t\t\t\t<key>Keywords</key>
      \t\t\t\t<array><string>Open</string><string>Document</string><string>File</string></array>
      \t\t\t\t<key>OutputUUID</key><string>7E2A3B4C-5D6E-7F8A-9B0C-1D2E3F4A5B6C</string>
      \t\t\t\t<key>UUID</key><string>8F3B4C5D-6E7F-8A9B-0C1D-2E3F4A5B6C7D</string>
      \t\t\t\t<key>UnlocalizedApplications</key>
      \t\t\t\t<array><string>Finder</string></array>
      \t\t\t\t<key>arguments</key>
      \t\t\t\t<dict>
      \t\t\t\t\t<key>0</key>
      \t\t\t\t\t<dict>
      \t\t\t\t\t\t<key>default value</key><string></string>
      \t\t\t\t\t\t<key>name</key><string>appPath</string>
      \t\t\t\t\t\t<key>required</key><string>0</string>
      \t\t\t\t\t\t<key>type</key><string>0</string>
      \t\t\t\t\t\t<key>uuid</key><string>0</string>
      \t\t\t\t\t</dict>
      \t\t\t\t</dict>
      \t\t\t\t<key>conversionLabel</key><integer>0</integer>
      \t\t\t\t<key>isViewVisible</key><integer>1</integer>
      \t\t\t\t<key>location</key><string>664.000000:228.000000</string>
      \t\t\t\t<key>nibPath</key>
      \t\t\t\t<string>/System/Library/Automator/Open Finder Items.action/Contents/Resources/Base.lproj/main.nib</string>
      \t\t\t</dict>
      \t\t\t<key>isViewVisible</key><integer>1</integer>
      \t\t</dict>
      \t</array>
      \t<key>connectors</key><dict/>
      \t<key>workflowMetaData</key>
      \t<dict>
      \t\t<key>applicationBundleID</key><string>com.apple.finder</string>
      \t\t<key>applicationBundleIDsByPath</key>
      \t\t<dict><key>/System/Library/CoreServices/Finder.app</key><string>com.apple.finder</string></dict>
      \t\t<key>applicationPath</key><string>/System/Library/CoreServices/Finder.app</string>
      \t\t<key>applicationPaths</key>
      \t\t<array><string>/System/Library/CoreServices/Finder.app</string></array>
      \t\t<key>inputTypeIdentifier</key><string>com.apple.Automator.fileSystemObject</string>
      \t\t<key>outputTypeIdentifier</key><string>com.apple.Automator.nothing</string>
      \t\t<key>presentationMode</key><integer>15</integer>
      \t\t<key>processesInput</key><false/>
      \t\t<key>serviceApplicationBundleID</key><string>com.apple.finder</string>
      \t\t<key>serviceApplicationPath</key><string>/System/Library/CoreServices/Finder.app</string>
      \t\t<key>serviceInputTypeIdentifier</key><string>com.apple.Automator.fileSystemObject</string>
      \t\t<key>serviceOutputTypeIdentifier</key><string>com.apple.Automator.nothing</string>
      \t\t<key>serviceProcessesInput</key><false/>
      \t\t<key>systemImageName</key><string>NSActionTemplate</string>
      \t\t<key>useAutomaticInputType</key><false/>
      \t\t<key>workflowTypeIdentifier</key><string>com.apple.Automator.servicesMenu</string>
      \t</dict>
      </dict>
      </plist>
    WFLOW

    # Registering the workflow is not enough: Finder hides a service from the
    # context menu unless pbs's own preferences opt it in. This entry is
    # required, not cosmetic — deleting it makes the Quick Action disappear even
    # though the workflow is still on disk and still registered with pbs.
    #
    # The key contains "(null) - ", which both `defaults` (parses it as a value)
    # and PlistBuddy (splits on the spaces and colons) mangle. plutil's -insert
    # takes it literally, so go through an exported copy and import it back —
    # editing ~/Library/Preferences/pbs.plist directly would be overwritten by
    # cfprefsd, which caches it.
    prefs = "#{staged_path}/pbs-services.plist"
    system_command "/usr/bin/defaults", args: ["export", "pbs", prefs]
    key = "NSServicesStatus.(null) - #{service_name} - runWorkflowAsService"
    # -remove first so reinstalling does not fail on an existing key. On a first
    # install there is nothing to remove, so discard the output too — otherwise
    # plutil's "No value to remove" lands in the middle of a successful install
    # and reads like a failure.
    system_command "/usr/bin/plutil", args:         ["-remove", key, prefs],
                                      must_succeed: false,
                                      print_stdout: false,
                                      print_stderr: false
    system_command "/usr/bin/plutil", args: [
      "-insert", key, "-xml",
      # Booleans, not integers: that is what macOS writes for the services it
      # manages itself, and `defaults read` renders true as 1 either way.
      "<dict><key>presentation_modes</key><dict>" \
      "<key>ContextMenu</key><true/>" \
      "<key>FinderPreview</key><true/>" \
      "<key>ServicesMenu</key><true/>" \
      "<key>TouchBar</key><true/>" \
      "</dict></dict>", prefs
    ]
    system_command "/usr/bin/defaults", args: ["import", "pbs", prefs]
    FileUtils.rm(prefs)

    # Without these the entry does not show up until the next login: pbs caches
    # the service list, and Finder caches the menu built from it.
    system_command "/System/Library/CoreServices/pbs", args: ["-flush"]
    system_command "/usr/bin/killall", args:         ["-HUP", "Finder"],
                                       must_succeed: false,
                                       print_stdout: false,
                                       print_stderr: false
  end

  uninstall_postflight do
    require "fileutils"

    FileUtils.rm_r service_path, force: true

    # Drop the preferences entry too, so an uninstall leaves nothing behind.
    prefs = "#{Dir.home}/Library/Caches/dex-pbs-services.plist"
    system_command "/usr/bin/defaults", args: ["export", "pbs", prefs]
    system_command "/usr/bin/plutil", args: [
      "-remove", "NSServicesStatus.(null) - #{service_name} - runWorkflowAsService", prefs
    ], must_succeed: false, print_stdout: false, print_stderr: false
    system_command "/usr/bin/defaults", args: ["import", "pbs", prefs]
    FileUtils.rm(prefs)

    system_command "/System/Library/CoreServices/pbs", args: ["-flush"]
    system_command "/usr/bin/killall", args:         ["-HUP", "Finder"],
                                       must_succeed: false,
                                       print_stdout: false,
                                       print_stderr: false
  end

  zap trash: [
    "~/.dex",
    "~/.dex-shared",
    "~/Library/Application Support/Dex",
    "~/Library/Caches/com.dex.dex",
    "~/Library/Caches/com.dex.dex.ShipIt",
    "~/Library/HTTPStorages/com.dex.dex",
    "~/Library/Preferences/com.dex.dex.plist",
    "~/Library/Saved Application State/com.dex.dex.savedState",
  ]

  caveats <<~EOS
    Dex is ad-hoc signed rather than notarized with an Apple Developer
    certificate. The quarantine flag is stripped during install, so the app
    opens normally, but `spctl` will still report it as rejected and macOS may
    warn on first launch.
  EOS
end
