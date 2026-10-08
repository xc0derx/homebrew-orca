class Orca < Formula
  desc "IDE for orchestrating AI coding agents across terminals and worktrees"
  homepage "https://onorca.dev/"
  version "1.4.222"
  license "MIT"

  on_arm do
    url "https://github.com/stablyai/orca/releases/download/v#{version}/orca-linux-arm64.AppImage",
        using: :nounzip
    sha256 "fc36305c09c6942adb7fbf42ba01cee58fed17de9c618db42d76f3fa02110444"
  end
  on_intel do
    url "https://github.com/stablyai/orca/releases/download/v#{version}/orca-linux.AppImage",
        using: :nounzip
    sha256 "3ffbc27329bb427d6ddcb7e408cf7c2d5c888602d4b0f4b98acfd74dd5ba5eb5"
  end

  depends_on :linux

  def install
    appimage = Dir["*.AppImage"].fetch(0)
    chmod 0755, appimage
    system "./#{appimage}", "--appimage-extract"
    libexec.install Dir["squashfs-root/*"]
    bin.install_symlink libexec/"resources/bin/orca-ide"

    desktop = libexec/"orca-ide.desktop"
    inreplace desktop, /^Exec=.*$/, "Exec=\"#{opt_libexec}/orca-ide\" %U"
    inreplace desktop, /^Icon=.*$/, "Icon=#{opt_libexec}/orca-ide.png"
    (share/"applications").install desktop
  end

  def caveats
    <<~EOS
      Orca requires your distribution's Electron runtime libraries (GTK 3, NSS,
      ALSA, AT-SPI and X11/GBM) and unprivileged user namespaces for its sandbox.
      See the tap README for Linux prerequisites and desktop integration.
      Run the CLI with orca-ide. Update with brew upgrade --formula #{full_name};
      the extracted AppImage cannot update itself in place.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/orca-ide --version")
    assert_match "serve", shell_output("#{bin}/orca-ide --help")
  end
end
