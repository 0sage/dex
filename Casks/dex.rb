# Homebrew cask for Dex. This repository doubles as its own tap:
#
#   brew tap 0sage/dex https://github.com/0sage/dex.git
#   brew install --cask --no-quarantine dex
#
# `version` and `sha256` are rewritten by .github/workflows/release.yml on every
# tagged build, so this file always points at the latest release.
cask "dex" do
  version "1.126.0"
  sha256 :no_check

  url "https://github.com/0sage/dex/releases/download/v#{version}/Dex-darwin-arm64-#{version}.zip"
  name "Dex"
  desc "macOS-only VS Code fork: files left, editor centre, terminal right"
  homepage "https://github.com/0sage/dex"

  depends_on macos: ">= :big_sur"
  depends_on arch: :arm64

  app "Dex.app"

  # The CLI shipped inside the bundle, so `dex .` works from a terminal. It is
  # named after product.json's applicationName, which this fork sets to `dex`.
  binary "#{appdir}/Dex.app/Contents/Resources/app/bin/dex"

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

  caveats do
    <<~EOS
      Dex is ad-hoc signed rather than notarized with an Apple Developer
      certificate, so it must be installed with:

        brew install --cask --no-quarantine dex

      Without that flag Gatekeeper will refuse to open the app.
    EOS
  end
end
