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
