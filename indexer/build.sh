#!/usr/bin/env bash

set -e

export all_proxy=$http_proxy
export https_proxy=$http_proxy
APP_DIR="${STACKATO_DOCUMENT_ROOT}"
OUT_DIR="${APP_DIR}/build-root"
KOMODO_DIR="${OUT_DIR}/komodo"

[ -d "${OUT_DIR}" ] || mkdir -p "${OUT_DIR}"
svn checkout --non-interactive http://svn.openkomodo.com/repos/openkomodo/trunk "${KOMODO_DIR}"
DATE="$(date -R -d "$(svn info --xml "${KOMODO_DIR}" | grep '<date>' | sed 's@<[^>]*>@@g')")"

( cd "${KOMODO_DIR}/mozilla" &&
  python build.py configure   \
    --moz-src=1800            \
    --komodo-version=8.10     \
    --release                 \
    --no-strip                \
    --moz-objdir=obj-release  \
    --gcc=clang               \
    --gxx=clang++             \
)

MOZILLA_DIR="${KOMODO_DIR}/mozilla/build/$(cd ${KOMODO_DIR}/mozilla && python -c 'import config; print config.srcTreeName')/mozilla"
MOZ_OBJ_DIR="${MOZILLA_DIR}/obj-release"
[ -d "${MOZ_OBJ_DIR}" ] || mkdir -p "${MOZ_OBJ_DIR}"

export LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${STACKATO_DOCUMENT_ROOT}/dxr/trilite/"

cat >"${OUT_DIR}/dxr.config" <<-EOF

	[DXR]
	target_folder       = ${STACKATO_FILESYSTEM}
	nb_jobs             = 2
	temp_folder         = ${OUT_DIR}/temp
	log_folder          = ${OUT_DIR}/logs
	enabled_plugins     = pygmentize clang
	generated_date      = ${DATE}
	template            = ${APP_DIR}/dxr/dxr/templates

	[Komodo]
	source_folder       = ${KOMODO_DIR}
	build_command       = python util/black/bk.py distclean     && \
	                        python util/black/bk.py reconfigure && \
	                        python util/black/bk.py build
	object_folder       = ${KOMODO_DIR}/build/release
	ignore_patterns     = .hg .git .svn .bzr .deps .libs *.pyc
	                        /mozilla/build/
	                        /build/
	                        /src/codeintel/test2/scan_actual/
	                        /src/codeintel/test2/scan_inputs/unicode/
	                        /src/codeintel/test2/tmp*/
	order               = 2

	[Mozilla]
	source_folder       = ${MOZILLA_DIR}
	build_command       = cd "${KOMODO_DIR}/mozilla" && \
	                        python build.py             \
	                          distclean                 \
	                          src                       \
	                          src_pyxpcom               \
	                          patch                     \
	                          patch_pyxpcom             \
	                          patch_komodo              \
	                          configure_mozilla         \
	                          mozilla                   \
	                          pluginsdk                 \
	                          mbsdiff                   \
	                          libmar                    \
	                          pyxpcom                   \
	                          silo_python               \
	                          regmozbuild               \
	                          #
	object_folder       = ${MOZ_OBJ_DIR}
	order               = 1

	[Template]
	footer_text         =

	EOF

dxr-build.py -f "${OUT_DIR}/dxr.config"
