# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Build and Development
- `flutter pub get` - Install dependencies
- `flutter run` - Run the application 
- `dart run build_runner build -d` - Generate required files (localization, code generation)
- `flutter test` - Run unit tests
- `flutter test integration_test/` - Run integration tests
- `flutter analyze` - Static code analysis and linting
- `flutter format .` - Format code

### Code Generation
- Run `dart run build_runner build -d` after installing dependencies or updating localization files
- This generates files needed by `flutter_intl` and other code generators

## Architecture Overview

### State Management: Riverpod
- Uses **Riverpod** for dependency injection and state management
- Providers are organized by feature in `features/{feature}/providers/`
- **Notifier pattern** for complex state logic (authentication, order management)
- Notifiers encapsulate business logic and expose state via providers

### Data Layer
- **Sembast** NoSQL database for local persistence
- Database initialization in `shared/providers/mostro_database_provider.dart`
- Repository pattern: All data access through repository classes in `data/repositories/`
- Models exported through `data/models.dart`

### Nostr Integration
- **NostrService** (`services/nostr_service.dart`) manages relay connections and messaging
- All Nostr protocol interactions go through this service
- **MostroFSM** (`core/mostro_fsm.dart`) manages order state transitions

### Navigation and UI
- **GoRouter** for navigation (configured in `core/app_routes.dart`)
- **flutter_intl** for internationalization (`l10n/` directory)
- Background services in `background/` for notifications and data sync

### Key Architecture Patterns
- Feature-based organization: `features/{feature}/{screens|providers|notifiers|widgets}/`
- Shared utilities and widgets in `shared/`
- Repository pattern for data access
- Provider pattern for dependency injection
- FSM pattern for order lifecycle management

### Testing Structure
- Unit tests in `test/` directory
- Integration tests in `integration_test/`
- Mocks generated using Mockito in `test/mocks.dart`

## Development Guidelines

### State Management
- Use Riverpod for all state management
- Encapsulate business logic in Notifiers
- Access data only through repository classes
- Use post-frame callbacks for side effects like SnackBars/dialogs

### Code Organization
- Follow existing feature-based folder structure
- Keep UI code declarative and side-effect free
- Use `S.of(context).yourKey` for all user-facing strings
- Refer to existing features (order, chat, auth) for implementation patterns

### Key Services and Components
- **MostroService** - Core business logic and Mostro protocol handling
- **NostrService** - Nostr protocol connectivity
- **Background services** - Handle notifications and background tasks
- **Key management** - Cryptographic key handling and storage
- **Exchange service** - Fiat/Bitcoin exchange rate handling

## Internationalization (i18n)

### Current Localization Setup
- **Primary languages**: English (en), Spanish (es), Italian (it)
- **ARB files location**: `lib/l10n/`
  - `intl_en.arb` - English (base language)
  - `intl_es.arb` - Spanish translations
  - `intl_it.arb` - Italian translations
- **Generated files**: `lib/generated/l10n.dart` and language-specific files
- **Usage**: Import `import 'package:mostro_mobile/generated/l10n.dart';` and use `S.of(context)!.keyName`

### Localization Best Practices
- **Always use localized strings**: Replace hardcoded text with `S.of(context)!.keyName`
- **ARB file structure**: Add new keys to all three ARB files (en, es, it)
- **Parameterized strings**: Use proper ARB metadata for strings with parameters
- **Regenerate after changes**: Run `dart run build_runner build -d` after ARB modifications
- **Context usage**: Pass BuildContext to methods that need localization

### TimeAgo Localization
- **Package**: Uses `timeago` package for relative time formatting
- **Setup**: Locales configured in `main.dart` with `timeago.setLocaleMessages()`
- **Implementation**: Custom `timeAgoWithLocale()` method in NostrEvent extension
- **Usage**: Automatically uses app's current locale for "hace X horas" vs "hours ago"

## Code Quality Standards

### Flutter Analyze
- **Target**: Zero `flutter analyze` issues
- **Deprecation handling**: Always use latest APIs (e.g., `withValues()` instead of `withOpacity()`)
- **BuildContext async gaps**: Always check `mounted` before using context after async operations
- **Imports**: Remove unused imports and dependencies
- **Immutability**: Use `const` constructors where possible

### Git Workflow
- **Branch naming**: Feature branches like `feat/feature-name`
- **Commit messages**: Descriptive messages following conventional commits
- **No Claude references**: Don't include Claude/AI references in commit messages
- **Code review**: All changes should pass `flutter analyze` before commit

## Project Context & Recent Work

### Major Features Completed
1. **Comprehensive Spanish/Italian Localization**
   - Added 73+ new localization keys across all screens
   - Localized order flow, payment screens, trade management
   - Fixed timeago package to show "hace X horas" instead of "hours ago"
   - All user-facing strings now properly internationalized

2. **Code Quality Improvements**
   - Resolved 54 Flutter analyze issues down to zero
   - Updated all deprecated APIs to modern Flutter standards
   - Fixed BuildContext async gaps with proper mounted checks
   - Cleaned up unused code and imports

3. **Architecture Enhancements**
   - Implemented proper timeago localization system
   - Enhanced NostrEvent extension with locale-aware methods
   - Improved error handling and user feedback

### Key Files Recently Modified
- **Localization**: `lib/l10n/*.arb`, `lib/generated/l10n*.dart`
- **Core models**: `lib/data/models/nostr_event.dart` (timeago localization)
- **UI components**: Multiple widget files for string localization
- **Main app**: `lib/main.dart` (timeago setup)
- **Order flow**: Take order, trade detail, payment screens

### Testing & Quality Assurance
- All tests passing with proper mock implementations
- Zero Flutter analyze issues maintained
- Comprehensive localization testing across languages
- Background service integration verified

## User Preferences & Working Style

### Development Approach
- **Systematic implementation**: Break complex tasks into manageable steps
- **Quality focus**: Always run `flutter analyze` and fix issues
- **Documentation**: Update this file when making architectural changes
- **Testing**: Verify changes don't break existing functionality

### Communication Style
- **Concise responses**: Keep explanations brief and to the point
- **Code-first**: Show implementation rather than lengthy explanations
- **Problem-solving**: Focus on root cause analysis and systematic fixes
- **Best practices**: Always follow Flutter and Dart conventions

### Git Practices
- **Clean commits**: Focused, single-purpose commits
- **Descriptive messages**: Clear commit messages without AI references
- **Branch management**: Use feature branches for development
- **Push workflow**: Always test before pushing to remote

## Important File Locations

### Configuration Files
- `pubspec.yaml` - Dependencies and Flutter configuration
- `analysis_options.yaml` - Linting rules and code analysis
- `lib/core/app_routes.dart` - Navigation configuration
- `lib/core/app_theme.dart` - UI theme and styling

### Key Directories
- `lib/features/` - Feature-based organization
- `lib/shared/` - Shared utilities and components
- `lib/data/` - Models, repositories, and data management
- `lib/services/` - Core services (Nostr, Mostro, etc.)
- `lib/l10n/` - Internationalization files
- `test/` - Unit and integration tests

### Generated Files (Don't Edit Manually)
- `lib/generated/` - Generated localization files
- `*.g.dart` - Generated Riverpod and other code
- Platform-specific generated files

## Notes for Future Development

- Always maintain zero Flutter analyze issues
- Test localization changes in all supported languages
- Update this documentation when making architectural changes
- Follow existing patterns when adding new features
- Prioritize user experience and code maintainability

---

**Last Updated**: 2025-01-05  
**Flutter Version**: Latest stable  
**Dart Version**: Latest stable  
**Key Dependencies**: Riverpod, GoRouter, flutter_intl, timeago, dart_nostr