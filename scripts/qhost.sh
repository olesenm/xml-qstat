#!/bin/sh
# a quick fix for issue
#     http://gridengine.sunsource.net/issues/show_bug.cgi?id=2515
# place somewhere in your path - don't rely on the exit code
#
#
# But the wrapper also interprets these initial parameters:
#     SGE_CELL
#     SGE_ROOT (should be an absolute path)
#
# -----------------------------------------------------------------------------

#
# NB: using CDATA in the error messages doesn't seem to help with bad characters
#
error()
{
    echo "<?xml version='1.0'?><error>"
    while [ "$#" -ge 1 ]; do echo "$1"; shift; done
    echo "</error>"
    exit 1
}


# find initial SGE_* parameters
unset settings
while [ "$#" -gt 0 ]
do
    case "$1" in
    SGE_CELL=*)
        export SGE_CELL="${1##SGE_CELL=}"
        shift
        ;;
    SGE_ROOT=*)
        export SGE_ROOT="${1##SGE_ROOT=}"
        settings=true
        shift
        ;;
    *)
        break
        ;;
    esac
done


# require a good SGE_ROOT and an absolute path:
[ -d "$SGE_ROOT" -a "${SGE_ROOT##/}" != "$SGE_ROOT" ] || \
    error "invalid SGE_ROOT directory '$SGE_ROOT'"

# require a good SGE_CELL:
[ -d "$SGE_ROOT/${SGE_CELL:-default}" ] || \
    error "invalid SGE_CELL directory '$SGE_ROOT/${SGE_CELL:-default}'"


# this is the essential bit from settings.sh,
# but SGE_ROOT might be different
if [ ${settings:-false} = true ]
then
    if [ -x "$SGE_ROOT/util/arch" ]
    then
        PATH=$SGE_ROOT/bin/$($SGE_ROOT/util/arch):$PATH
        export PATH
    else
        error "'$SGE_ROOT/util/arch' not found"
    fi
fi


qhost "$@" | sed -e 's@xmlns=@xmlns:xsd=@'

# ----------------------------------------------------------------- end-of-file
