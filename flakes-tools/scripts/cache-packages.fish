# set temp directory for outputs for packages
set -q PATHS_FOR_PACKAGES || set PATHS_FOR_PACKAGES $(mktemp -t packages-XXXXXXXXXX)

set t $( nix flake show --json | jq -r --arg cur_sys "$CURRENT_SYSTEM" '.packages[$cur_sys]|(try keys[] catch "")' )

if test -n "$t"
    printf "%s\n" $t | xargs -I {} nix build --print-out-paths .#{} >$PATHS_FOR_PACKAGES
    cat $PATHS_FOR_PACKAGES | xargs -I {} nix-store -qR --include-outputs {} | cachix push $CACHIX_CACHE
end

rm $PATHS_FOR_PACKAGES
