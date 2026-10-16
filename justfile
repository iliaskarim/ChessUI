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

# Record replays on the iPhone simulator. Pass a name to record one: `just capture scholars-mate`.
capture replay="":
    #!/usr/bin/env zsh
    set -euo pipefail
    if [[ -z "{{ replay }}" ]]; then
      replays=(fools-mate scholars-mate loyd-stalemate)
    else
      replays=("{{ replay }}")
    fi
    for name in "${replays[@]}"; do
      scripts/capture-replay "$name"
    done

# Crop scholars-mate.mov to a square around the chess UI and write a GIF.
crop-scholars-mate:
    scripts/crop-scholars-mate

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

# `strict: true` in `.swiftlint.yml` already applies to lint and analyze.
# SwiftLint ignores `--strict` when `--fix` is set.
# Autocorrect SwiftLint violations, then format with SwiftFormat.
lint:
    swiftlint lint --fix .
    swiftformat .

# SwiftLint analyze on macOS and iOS. Pass one platform: `just analyze iOS`.
analyze platform="":
    #!/usr/bin/env zsh
    set -euo pipefail
    case "{{ platform }}" in
      "")
        bash scripts/swiftlint-analyze
        ;;
      macOS)
        bash scripts/swiftlint-analyze --destination platform=macOS
        ;;
      iOS)
        dest="$({{ just_executable() }} --quiet --justfile {{ justfile() }} _destination)"
        bash scripts/swiftlint-analyze --destination "$dest"
        ;;
      *)
        print -u2 "platform must be macOS or iOS"
        exit 1
        ;;
    esac

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
