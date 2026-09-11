# 03 — Coding Standards & Best Practices

## 1. Core Principles
- **Strict Null Safety**: No unchecked `!` assertions unless guaranteed by prior null check or framework contract.
- **Const Constructors**: Always use `const` constructors wherever possible to maximize widget rebuild optimization.
- **No Business Logic in Widgets**: Widgets are strictly declarative presentation elements. Business logic belongs in Use Cases and BLoCs.
- **No Magic Strings / Numbers**: Use `AppConstants`, `AppSpacing`, `AppRadius`, `AppColors`, and `StorageKeys`.
- **Feature Encapsulation**: Keep features decoupled. Cross-feature communication must happen through domain entities, shared core abstractions, or routing parameters.

---

## 2. BLoC / Cubit Standard
1. **Event Naming**: `[Feature][Subject][Action]Requested` / `Changed` / `Submitted` (e.g., `SplashCheckRequested`, `SeatSelectRequested`).
2. **State Naming**: `[Feature][State]` (e.g., `SplashInitial`, `SplashLoading`, `SplashLoaded`, `SplashError`).
3. **Equatability**: All states and events must extend `Equatable` to ensure accurate state transition diffing.
4. **State Completeness**: Every screen must account for:
   - **Initial**
   - **Loading / Skeleton**
   - **Loaded / Success**
   - **Empty**
   - **Error**
5. **No Direct Data Calls**: BLoCs only invoke UseCases; they never instantiate repositories or data sources directly.

---

## 3. Error Handling Standard
- Raw exceptions (`DioException`, `PostgrestException`, `HttpException`) must never bubble up into the Presentation layer.
- All repository implementations wrap data calls with `try-catch` blocks and use `ErrorHandler.handle(e)` to convert them into a domain `Failure`.
- Use the sealed `Result<T>` type with `.fold(onError: ..., onSuccess: ...)` for all repository and use case return signatures.

```dart
// Standard Repository Implementation Pattern
@override
ResultFuture<User> getUserProfile() async {
  try {
    final model = await remoteDataSource.getUserProfile();
    return Success(model.toEntity());
  } catch (e) {
    return Error(ErrorHandler.handle(e));
  }
}
```

---

## 4. UI & Widget Rules
- **Skeletonizer Loading**: Use `AppSkeleton` over indiscriminate progress spinners for content lists and cards.
- **Localization First**: All user-visible copy must come from ARB translations (`context.l10n.[key]`).
- **Responsive Layout**: Use `MediaQuery` / `LayoutBuilder` / `AppSpacing` tokens; never hardcode fixed screen pixel offsets.
- **Separation of Private Widgets**: Keep complex sub-trees in private widgets (`_HeaderView`, `_SeatItem`) or dedicated feature widget files to prevent excessive nesting.
