# mloody

`mloody` is an Objective-C / Objective-C++ macOS project scaffold for building a Bloody mouse driver stack with a **hexagonal architecture**.

The repository is intentionally layered so core behavior stays decoupled from macOS-specific I/O and transport details.

## Architecture

- `src/domain`: Business rules, entities, value objects, and pure policy.
- `src/application`: Use cases and `ports` (`@protocol`) that define dependencies.
- `src/adapters`: Inbound/outbound adapter implementations.
- `src/bootstrap`: Composition root (`main.mm`) where concrete adapters are wired.
- `tests/unit`: Unit-style tests targeting application + domain through in-memory adapters.

See `docs/architecture.md` for dependency direction and extension points.

## Build

```bash
cmake -S . -B build
cmake --build build
```

## Test

```bash
ctest --test-dir build --output-on-failure
```

## CLI (Current Scaffold)

```bash
./build/mloody list
./build/mloody apply --dpi 1600 --polling 1000 --lod 2
```

`list` uses the IOKit discovery adapter. `apply` routes through the application use case and currently fails with a clear message because Bloody-specific feature report protocol mapping is not yet implemented.

## Notes for Real Driver Work

- Modern macOS driver development favors DriverKit/system extensions over legacy kernel extensions.
- Bloody protocol work (feature reports, endpoint behavior, profile packet format) should be implemented in the outbound transport adapter without changing domain or use-case code.
