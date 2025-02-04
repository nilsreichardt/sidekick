import 'package:sidekick_core/sidekick_core.dart';

/// Finds the root of the repo
Repository findRepository() {
  final Directory packageHome =
      // Usually the dir is injected
      Repository.cliPackageDir ??
          // the actual dart .exe located in `build`
          File.fromUri(Platform.script).parent.parent;

  // Platform.executable can be used to detect if the script was executed
  // from the run script or via debugger

  bool isGitDir(Directory dir) => dir.directory('.git').existsSync();

  Directory? gitRoot = packageHome.findParent(isGitDir);
  // fallback to CWD
  gitRoot ??= entryWorkingDirectory.findParent(isGitDir);
  if (gitRoot == null) {
    error(
      'Could not find the root of the repository. Searched in '
      '${entryWorkingDirectory.absolute.path} and '
      '${packageHome.absolute.path}',
    );
  }
  return Repository(root: gitRoot);
}

/// The repository of the project
///
/// Might be a single dart project or multiple packages, or even non dart packages
class Repository {
  Repository({
    required this.root,
  });

  final Directory root;

  /// The location of the package
  ///
  /// Usually injected from the tool/run.sh script itself via `env.SIDEKICK_PACKAGE_HOME`
  static Directory? get cliPackageDir {
    final injectedEntryPointPath = env['SIDEKICK_PACKAGE_HOME'];
    if (injectedEntryPointPath == null || injectedEntryPointPath.isBlank) {
      return null;
    }
    final packageHome = Directory(normalize(injectedEntryPointPath));
    if (!packageHome.existsSync()) {
      error(
        'injected package home does not exist ${packageHome.absolute.path}',
      );
    }
    return packageHome;
  }

  static Directory get requiredCliPackage {
    final dir = cliPackageDir;
    if (dir == null) {
      throw "env.SIDEKICK_PACKAGE_HOME is not set";
    }
    return dir;
  }

  /// The location of the entrypoint
  ///
  /// Usually injected from the entrypoint itself via `env.SIDEKICK_ENTRYPOINT_HOME`
  static File? get entryPoint {
    final injectedEntryPointPath = env['SIDEKICK_ENTRYPOINT_HOME'];
    if (injectedEntryPointPath == null || injectedEntryPointPath.isBlank) {
      return null;
    }
    final entrypoint = File(normalize('$injectedEntryPointPath/$cliName'));
    if (!entrypoint.existsSync()) {
      error('injected entrypoint does not exist ${entrypoint.absolute.path}');
    }
    return entrypoint;
  }

  static File get requiredEntryPoint {
    final file = entryPoint;
    if (file == null) {
      throw "env.SIDEKICK_ENTRYPOINT_HOME is not set";
    }
    return file;
  }
}

extension FindInDirectory on Directory {
  /// Recursively goes up and tries to find a [Directory] matching [predicate]
  ///
  /// Returns `null` when reaching root (/) without a match
  Directory? findParent(bool Function(Directory dir) predicate) {
    var dir = this;
    while (true) {
      if (predicate(dir)) {
        return dir;
      }
      final parent = dir.parent;
      if (dir.toString() == parent.toString()) {
        // not found
        return null;
      }
      dir = dir.parent;
    }
  }
}
