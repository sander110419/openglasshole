# Contributing

Contributions are welcome, especially physical build reports with measurements.
Safety and reproducibility matter more than making the prototype look finished.

## Before a pull request

Run the relevant checks:

```sh
python3 -m unittest discover -s server/tests -v
python3 -m compileall -q server tools
python3 tools/check_bom.py
pio run --project-dir firmware
make -C hardware/cad check-release
python3 tools/check_repo.py
git diff --check
```

For hardware changes:

- change top-level CAD parameters rather than baking in an unmeasured module;
- regenerate every affected STL and record the OpenSCAD version;
- keep the combiner, battery, prescription-lens clearance, and snag-releasing
  padded-mount safety constraints intact;
- distinguish simulation/calculation from a real measurement;
- include printer, material, optical part, mass, eye-box, current, and runtime
  data in a build report;
- never call a design "safe," "sunlight readable," or "universal" without the
  scope and evidence needed for that claim.

For firmware/server changes, keep cue length and network operations bounded,
preserve cached offline playback, do not commit credentials, and never disable
TLS certificate checks.

By contributing, you agree that software contributions are provided under MIT
and hardware/CAD/schematic/documentation contributions under CERN-OHL-P-2.0.
