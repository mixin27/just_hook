## 0.0.2

- **Testing**: Added a comprehensive unit test suite (18 tests) covering the core framework and all provided hooks.
- **Framework Fix**: Fixed `HookKeys.didKeysChange` to correctly handle `null` keys, ensuring hooks like `usePrevious` work accurately across rebuilds.
- **Performance Optimization**: Optimized `useMemoized`, `usePagination`, and controller hooks (`useTextEditingController`, `useScrollController`, etc.) to prevent accidental disposals and re-creations when no keys are provided.
- **Stability**: Fixed a race condition in `usePagination` initialization and improved async test reliability.
- **CI/CD**: Enhanced the GitHub Actions workflow with strict analysis (`--fatal-infos`) and consistent Flutter commands.

## 0.0.1

- **Initial Release:** A lightweight, highly scalable, and structurally complete Flutter Hooks framework alternatively styled around React-Hooks.
- **Core Engine:** Added `Hook`, `HookState`, `HookWidget`, `HookElementMixin` for extensible hook support and `HookElement` for uncompromised widget lifecycles.
- **Standard Hooks:** Shipped `useState`, `useEffect`, and `useMemoized`.
- **Controller Hooks:** Shipped `useScrollController`, `usePageController`, `useFocusNode`, and `useTextEditingController`.
- **Advanced Networking:- **Initial Hook Suite\*\*: `useState`, `useEffect`, `useMemoized`, `useFuture`, `useStream`, `useTextEditingController`, `useScrollController`, `usePageController`, `useFocusNode`, `useIsMounted`, `useValueListenable`, `useListenable`, `useDebounced`, `useStreamController`.
- **Domain Hooks**: `usePagination` (infinite scroll), `useForm` (uncontrolled validation), `useAnimationController` (lifecycle-managed), `useQuery`/`useMutation`/`useSubscription` (REST/GraphQL).
- **Advanced Ecosystem**:
  - `useContext`, `useTheme`, `useMediaQuery` for reactive context access.
  - `useAppLifecycleState` for system event tracking.
- **Widget Support**:
  - `HookBuilder` for inline hook usage in any widget tree.
  - `StatefulHookWidget` for combining traditional `State` with Hooks.
- **Documentation**: Comprehensive inline docs and example application.
  strating all features interactively.
