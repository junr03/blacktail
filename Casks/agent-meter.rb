cask "agent-meter" do
  version "2805d3ae0742ed35a93961f1d27baf9fbf95eec1"
  sha256 "60ce63fd130ba0369bd2f388b1b6cdfaa8a854ad284c46d9728df69ff795f94b"

  url "https://codeload.github.com/amazingyyc/AgentMeter/tar.gz/#{version}"
  name "Agent Meter"
  desc "Menu bar monitor for coding agents in Rex and Ghostty"
  homepage "https://github.com/amazingyyc/AgentMeter"

  depends_on macos: :sonoma

  preflight_steps do
    write_file "AgentMeter-#{version}/scripts/build-with-clt-compat.sh", <<~SH
      #!/bin/sh
      set -eu

      project_dir="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
      developer_dir="$(/usr/bin/xcode-select -p)"

      case "$(/usr/bin/uname -m)" in
        arm64) interface_arch=arm64e ;;
        x86_64) interface_arch=x86_64 ;;
        *) echo "Agent Meter does not support this Mac architecture." >&2; exit 1 ;;
      esac

      case "$developer_dir" in
        */CommandLineTools)
          sdk_path=""
          for sdk_name in MacOSX26.5.sdk MacOSX26.sdk; do
            candidate="$developer_dir/SDKs/$sdk_name"
            if [ -d "$candidate" ]; then
              sdk_path="$candidate"
              break
            fi
          done

          if [ -z "$sdk_path" ]; then
            echo "Agent Meter needs Xcode or the macOS 26.5/26 SDK when using Command Line Tools alone." >&2
            exit 1
          fi

          swiftui_module="$sdk_path/System/Library/Frameworks/SwiftUI.framework/Modules/SwiftUI.swiftmodule"
          swiftui_interface="$swiftui_module/$interface_arch-apple-macos.swiftinterface"
          interface_version="$(
            /usr/bin/sed -n 's/.*-interface-compiler-version \\([^ ]*\\).*/\\1/p' "$swiftui_interface" |
              /usr/bin/head -n 1
          )"
          if [ -z "$interface_version" ]; then
            echo "Could not read the SwiftUI SDK compiler version from $swiftui_interface." >&2
            exit 1
          fi

          SDKROOT="$sdk_path" \\
          AGENT_METER_SWIFTC="$developer_dir/usr/bin/swiftc" \\
          AGENT_METER_SWIFTUI_INTERFACE_VERSION="$interface_version" \\
          CLANG_MODULE_CACHE_PATH="$project_dir/.build/module-cache" \\
          SWIFT_EXEC="$project_dir/.swiftc-compat" \\
          SWIFT_EXEC_MANIFEST="$project_dir/.swiftc-compat" \\
            /bin/zsh "$project_dir/scripts/build-app.sh"
          ;;
        *)
          /bin/zsh "$project_dir/scripts/build-app.sh"
          ;;
      esac
    SH
    write_file "AgentMeter-#{version}/.swiftc-compat", <<~SH
      #!/bin/sh
      exec "$AGENT_METER_SWIFTC" \\
        -Xfrontend -interface-compiler-version \\
        -Xfrontend "$AGENT_METER_SWIFTUI_INTERFACE_VERSION" \\
        "$@"
    SH
    set_permissions "AgentMeter-#{version}/scripts/build-with-clt-compat.sh", "0755"
    set_permissions "AgentMeter-#{version}/.swiftc-compat", "0755"
    run "/bin/sh",
        args: ["{{staged_path}}/AgentMeter-#{version}/scripts/build-with-clt-compat.sh"],
        writable_paths: ["AgentMeter-#{version}"],
        network_access: true
  end

  app "AgentMeter-#{version}/build/Agent Meter.app"

  uninstall quit: "dev.yyc.AgentMeter"

  caveats <<~EOS
    Agent Meter builds from source during installation. A Command Line Tools-only setup needs the macOS 26.5 or 26
    SDK; a full Xcode installation can use its selected SDK.
  EOS
end
