# Hexagonal Architecture in mloody

## Dependency Rule

Dependencies always point inward:

1. `domain` depends on nothing outside Foundation and itself.
2. `application` depends on `domain` and abstract `ports` only.
3. `adapters` depend on `application`/`domain` and implement `ports`.
4. `bootstrap` depends on everything and performs wiring.

No outward dependency should leak into `domain` or use cases.

## Layers

### Domain (`src/domain`)

- `MLDMouseDevice`: Core device entity.
- `MLDPerformanceProfile`: Immutable profile value object.
- `MLDProfilePolicy`: Validation policy for profile values.
- `MLDSupportedDeviceCatalog`: Supported vendor filtering policy.

### Application (`src/application`)

- `ports/MLDDeviceDiscoveryPort`: Input abstraction for device enumeration.
- `ports/MLDFeatureTransportPort`: Output abstraction for feature report transport.
- `MLDDiscoverSupportedDevicesUseCase`: Enumerates + filters supported devices.
- `MLDApplyPerformanceProfileUseCase`: Validates profile then sends through port.
- `MLDWriteFeatureReportUseCase`: Raw feature-report write path for direct device control.
- `MLDReadFeatureReportUseCase`: Raw feature-report read path for device introspection.

### Adapters (`src/adapters`)

- Outbound IOKit adapters:
  - `MLDIOKitDeviceDiscoveryAdapter`
  - `MLDIOKitFeatureTransportAdapter`
- Outbound test adapters:
  - `MLDInMemoryDeviceDiscoveryAdapter`
  - `MLDInMemoryFeatureTransportAdapter`
- Inbound CLI adapter:
  - `MLDCliApplication`

## Extension Path

1. Capture T50 feature-report map with `feature-get`/`feature-set` and encode stable packet types.
2. Add Bloody HID protocol packet encoding/decoding in `MLDIOKitFeatureTransportAdapter`.
3. Wire known packet encoders to `MLDApplyPerformanceProfileUseCase`.
4. Keep protocol constants and codec logic adapter-local unless they represent a domain concept.
5. Add integration tests for adapter behavior while keeping unit tests on use-case/domain rules.
