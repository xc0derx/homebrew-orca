class OrcaCli < Formula
  desc "CLI and headless server for orchestrating AI coding agents"
  homepage "https://onorca.dev/"
  version "1.4.222"
  license "MIT"

  if Hardware::CPU.arm?
    url "https://github.com/stablyai/orca/releases/download/v#{version}/orca-linux-arm64.AppImage",
        using: :nounzip
    sha256 "fc36305c09c6942adb7fbf42ba01cee58fed17de9c618db42d76f3fa02110444"
  else
    url "https://github.com/stablyai/orca/releases/download/v#{version}/orca-linux.AppImage",
        using: :nounzip
    sha256 "3ffbc27329bb427d6ddcb7e408cf7c2d5c888602d4b0f4b98acfd74dd5ba5eb5"
  end

  depends_on :linux
  conflicts_with "orca", because: "both install the orca-ide command"

  resource "node-runtime" do
    if Hardware::CPU.arm?
      url "https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-arm64.tar.gz"
      sha256 "724282c3b43aec998aa9527380465b45d229e021b58035f5f4f63095eabfe5d5"
    else
      url "https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.gz"
      sha256 "6e1db87ef58b8819e5d5402eff1536491b18edd8eb7bee5ef7897876e88dc5ff"
    end
  end

  def install
    require "digest"
    require "json"

    appimage = Dir["*.AppImage"].fetch(0)
    chmod 0755, appimage
    system "./#{appimage}", "--appimage-extract"
    resources = buildpath/"squashfs-root/resources"
    (libexec/"out").install resources/"app.asar.unpacked/out/cli",
                           resources/"app.asar.unpacked/out/shared",
                           resources/"app.asar.unpacked/out/package.json"
    %w[jsonc-parser tweetnacl ws yaml zod].each do |name|
      (libexec/"node_modules").install resources/"node_modules"/name
    end

    template = resources/"orcad-template"
    manifest = JSON.parse((template/"orcad-template.json").read)
    target = Hardware::CPU.arm? ? "linux-arm64-glibc" : "linux-x64-glibc"
    files = manifest.fetch("commonSha256").merge(manifest.fetch("targets").fetch(target).fetch("files"))
    files.each do |name, sha|
      source = manifest.fetch("commonSha256").key?(name) ? template/name : template/"targets"/target/name
      odie "Invalid server artifact: #{name}" if Digest::SHA256.file(source).hexdigest != sha
      destination = libexec/"server"/name
      destination.dirname.mkpath
      cp source, destination
    end
    resource("node-runtime").stage { (libexec/"runtime").install "bin/node" }
    runtime_sha = (libexec/"server/.runtime-node").read.strip
    odie "Node runtime does not match Orca's native modules" if
      Digest::SHA256.file(libexec/"runtime/node").hexdigest != runtime_sha

    (bin/"orca-ide").write <<~SH
      #!/bin/bash
      set -e
      export ORCA_VERSION="#{version}"
      if [ "${1-}" = serve ]; then
        shift
        exec "#{opt_libexec}/runtime/node" "#{opt_libexec}/server/orcad.js" --bind 127.0.0.1 "$@"
      fi
      exec "#{opt_libexec}/runtime/node" "#{opt_libexec}/out/cli/index.js" "$@"
    SH
    chmod 0755, bin/"orca-ide"
  end

  def caveats
    <<~EOS
      Run orca-ide serve to start the Node server on loopback without Electron.
      Use --bind 0.0.0.0 --pairing-address HOST to allow remote clients.
      The Node backend does not provide desktop windows or Electron browser panes.
      Update with brew upgrade #{full_name}.
    EOS
  end

  test do
    require "json"

    assert_match version.to_s, shell_output("#{bin}/orca-ide --version")
    ENV["ORCA_USER_DATA_PATH"] = (testpath/"profile").to_s
    log = testpath/"serve.log"
    pid = spawn bin/"orca-ide", "serve", "--port", free_port.to_s, "--no-pairing",
                out: log.to_s, err: log.to_s
    begin
      status = nil
      30.times do
        sleep 1
        output = IO.popen([bin/"orca-ide", "status", "--json"], &:read)
        status = JSON.parse(output)
        break if status["ok"]
      end
      assert status.fetch("ok"), log.read
    ensure
      if Process.waitpid(pid, Process::WNOHANG).nil?
        Process.kill("TERM", pid)
        Process.wait(pid)
      end
    end
  end
end
