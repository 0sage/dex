# Homebrew cask for Dex. This repository doubles as its own tap:
#
#   brew tap 0sage/dex https://github.com/0sage/dex.git
#   brew install --cask --no-quarantine dex
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
