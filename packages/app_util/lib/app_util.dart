/// Small things both applications need exactly the same way.
///
/// Each file here was written once, in one application, after a bug the other
/// one either had too or had hand-rolled around. None of them takes an opinion
/// that differs between the two: where they do differ — which scheme a bare
/// host gets, which error code a 429 becomes — that is a parameter, or the
/// application's own switch over what this package classified.
library;

export 'src/demo_http_adapter.dart';
export 'src/dio_failure.dart';
export 'src/format_bytes.dart';
export 'src/hex_color.dart';
export 'src/json_coerce.dart';
export 'src/platform_query.dart';
export 'src/server_url.dart';
export 'src/text_measure.dart';
export 'src/user_number.dart';
