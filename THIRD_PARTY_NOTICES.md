# Provenance

The attribution and budget logic, fixtures and independent test oracle were
implemented for MoonTraceGate with AI assistance. Apache-2.0 applies.

The Node I/O adapter, PS wrapper and installer, and bounded JSON text preflight
are adapted from JingLan0v0/MoonQuorum, commit f158d9d5215c1fbd4f765b91dfff4c1e9c17deb8
(Apache-2.0), which credits earlier MoonSTN and MoonJMES infrastructure.
The only runtime MoonBit dependency is its standard library.

The Chrome JSON duration event model is described in the Perfetto documentation
https://perfetto.dev/docs/getting-started/other-formats#chrome-json-format .
The format is used as a reference. Perfetto source and example data are not
bundled. This implementation covers synchronous duration event subsets.
