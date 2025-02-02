action=$1
appid=$2

shift 2

case $action in
    desc)
        echo "asserts a Mac app is installed and up-to-date from the App Store"
        echo " via the 'mas' utility https://github.com/argon/mas"
        echo "app id is required, can be obtained from 'mas' utility, name is optional"
        echo "> mas 497799835 Xcode    (installs/upgrades Xcode)"
        ;;

    status)
        baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
        needs_exec "mas" || return $STATUS_FAILED_PRECONDITION
        bake mas account
        # Workaround for mas account failing on macOS >= 12 (i.e. Darwin >= 21)
        # https://github.com/borksh/bork/issues/42
        if [ "$?" -gt 0 ]; then
          release=$(get_baking_platform_release)
          str_matches "$release" "^21\." || return $STATUS_FAILED_PRECONDITION
        fi
        bake mas list | grep -E "^$appid" > /dev/null
        [ "$?" -gt 0 ] && return $STATUS_MISSING
        bake mas outdated | grep -E "^$appid" > /dev/null
        [ "$?" -eq 0 ] && return $STATUS_OUTDATED
        return $STATUS_OK
        ;;

    install) bake mas install $appid ;;

    upgrade) bake mas upgrade ;;

    inspect)
        baking_platform_is "Darwin" || return $STATUS_UNSUPPORTED_PLATFORM
        needs_exec "mas" || return $STATUS_FAILED_PRECONDITION
        installed=$(bake mas list)
        while IFS= read -r app; do
            echo "ok mas $app" | sed -E 's/ \([0-9\.]+\)$//g'
        done <<< "$installed"

        ;;

    remove) bake mas uninstall $appid ;;

    *) return 1 ;;
esac
