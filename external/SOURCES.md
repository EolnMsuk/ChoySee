# Vendored dependency sources

These are ordinary source folders for Choicy, suitable for uploading through the
GitHub website. Git and submodule links are not needed to use these copies.

| Folder | Upstream repository | Pinned commit |
| --- | --- | --- |
| `litehook` | [opa334/litehook](https://github.com/opa334/litehook) | `0d9d17afc011d2a8dfe67a4f7803ff99143d0f0d` |
| `ChOma` | [opa334/ChOma](https://github.com/opa334/ChOma) | `2fcc1fc51f6eb778756ccdee3c809bf83a767996` |

The upstream C source and header files are unchanged. Each folder retains its
upstream `LICENSE` and `README.md`. LiteHook also includes `external/include`,
which Choicy's main Makefile requires. Neither pinned archive has nested submodules.

Included files:

- `litehook/src/`, `litehook/external/include/`, `litehook/LICENSE`, and `litehook/README.md`.
- `ChOma/src/`, `ChOma/LICENSE`, and `ChOma/README.md`.

Upstream sample/test projects, editor files, signing certificates, and ChOma's
prebuilt OpenSSL libraries are omitted. Choicy compiles the vendored `src/*.c`
files directly and does not reference those omitted files or libraries.

Source archives used:

| Archive | SHA-256 |
| --- | --- |
| [LiteHook source ZIP](https://codeload.github.com/opa334/litehook/zip/0d9d17afc011d2a8dfe67a4f7803ff99143d0f0d) | `27767335ed85ade625369a2a20739da986d912f09cf8815523accf3da6a3f790` |
| [ChOma source ZIP](https://codeload.github.com/opa334/ChOma/zip/2fcc1fc51f6eb778756ccdee3c809bf83a767996) | `730ed98f50590ac341f1158805f9df9cc061e113418722385c62d380e83af846` |

To upload, use your GitHub repository's root page, choose **Add file > Upload
files**, and upload the local `external` folder so these paths remain
`external/litehook/src/litehook.h` and `external/ChOma/src/MachO.h`. Do not add an
extra `Choicy` directory or the archive's commit-suffixed wrapper directory.
Upload the updated `.github/workflows/build.yml` separately if it is not already
in your repository. Its pinned checkout fallbacks are skipped when these source
headers are present. Start a fresh workflow run after committing the upload.

Local checks verify archive integrity, revision IDs, source file contents,
required include paths, and quoted local header references. Compilation and
package/device testing remain owner checks; no package build was run here.
