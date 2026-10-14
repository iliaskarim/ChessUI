set shell := ["zsh", "-cu"]

# List the snapshot commands.
default:
    @just --list

# Run the snapshot tests. Pass an identifier to run one: `just test ChessUITests/ChessUITests/testChessUI`.
test only="ChessUITests":
    #!/usr/bin/env zsh
    set -euo pipefail
    dest="$({{ just_executable() }} --quiet --justfile {{ justfile() }} _destination)"
    xcodebuild test \
      -scheme ChessUI \
      -destination "$dest" \
      -only-testing:{{ only }} \
      -skipPackagePluginValidation

# Re-record snapshots (`failed`, or `all`). The run fails on purpose; then run `just test`.
record mode="failed":
    #!/usr/bin/env zsh
    set -euo pipefail
    case "{{ mode }}" in
      all|failed|missing|never) ;;
      *)
        print -u2 "mode must be all, failed, missing, or never"
        exit 1
        ;;
    esac
    dest="$({{ just_executable() }} --quiet --justfile {{ justfile() }} _destination)"
    TEST_RUNNER_SNAPSHOT_TESTING_RECORD={{ mode }} \
      xcodebuild test \
        -scheme ChessUI \
        -destination "$dest" \
        -only-testing:ChessUITests \
        -skipPackagePluginValidation

# Use DESTINATION if set, otherwise a booted iPhone, otherwise an iPhone 17.
[private]
_destination:
    #!/usr/bin/env zsh
    set -euo pipefail
    if [[ -n "${DESTINATION:-}" ]]; then
      print -r -- "$DESTINATION"
      exit 0
    fi
    id="$(xcrun simctl list devices booted | awk -F '[()]' '/iPhone/ { print $2; exit }')"
    if [[ -z "$id" ]]; then
      id="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17 \(/ { id=$2 } END { print id }')"
    fi
    if [[ -z "$id" ]]; then
      print -u2 "No iPhone simulator found. Set DESTINATION to an xcodebuild destination."
      exit 1
    fi
    print -r -- "platform=iOS Simulator,id=$id"
