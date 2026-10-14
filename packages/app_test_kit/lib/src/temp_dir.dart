import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// A temporary directory the test owns, so whatever a download leaves in the
/// cache can be listed afterwards. Assign it to `PathProviderPlatform.instance`
/// in `setUp` and delete the directory in `tearDown`.
class TempDirProvider extends PathProviderPlatform {
  TempDirProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}
