# Changelog

## [1.1.0](https://github.com/doublewordai/bit-harbor/compare/v1.0.0...v1.1.0) (2025-08-15)


### Features

* remove kruise dependency and update values.yaml ([f26decc](https://github.com/doublewordai/bit-harbor/commit/f26deccc145abd6a0704cb8193b3504b86e93910))

## [1.0.0](https://github.com/doublewordai/bit-harbor/compare/v0.2.3...v1.0.0) (2025-08-14)


### ⚠ BREAKING CHANGES

* convert from daemonsets to using kruise advancedcronjobs and broadcastjobs for refreshing images over lifetime of the cluster

### Features

* convert from daemonsets to using kruise advancedcronjobs and broadcastjobs for refreshing images over lifetime of the cluster ([2ff9807](https://github.com/doublewordai/bit-harbor/commit/2ff9807d2d25803b874d02beee3667e2afc51357))

## [0.2.3](https://github.com/doublewordai/bit-harbor/compare/v0.2.2...v0.2.3) (2025-08-13)


### Bug Fixes

* only restart on failure ([1ad5ed8](https://github.com/doublewordai/bit-harbor/commit/1ad5ed8412b7e8a06d8a33f62257b4fffd69ba27))

## [0.2.2](https://github.com/doublewordai/bit-harbor/compare/v0.2.1...v0.2.2) (2025-08-13)


### Bug Fixes

* only use one container for the pre-porter DaemonSet ([eb67914](https://github.com/doublewordai/bit-harbor/commit/eb679145271d3743b6b145e277f4561eb423f462))

## [0.2.1](https://github.com/doublewordai/bit-harbor/compare/v0.2.0...v0.2.1) (2025-08-13)


### Bug Fixes

* bug with using model name in path of image rather than tag ([0e16558](https://github.com/doublewordai/bit-harbor/commit/0e1655830648f212cf82524b32348eb9e90e3035))

## [0.2.0](https://github.com/doublewordai/bit-harbor/compare/v0.1.0...v0.2.0) (2025-08-13)


### Features

* add pre-porter helm chart which prepulls requested images on each of your nodes before use. Also adds release-please config for automated releases. ([41fe0e5](https://github.com/doublewordai/bit-harbor/commit/41fe0e51e4c926357b0bbd2f1fd5fb09671729c1))


### Bug Fixes

* release please manifest path, added documentation for pre-porter ([525157b](https://github.com/doublewordai/bit-harbor/commit/525157b43a5ad9ba14e7bf2d3a477efbb3526dfc))
