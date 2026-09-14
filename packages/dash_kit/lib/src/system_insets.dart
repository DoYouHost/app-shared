import 'package:flutter/widgets.dart';

/// [base] with the system navigation bar's height added to its bottom, for a
/// screen-level scroll view that would otherwise end under the bar on Android
/// 15. A screen inside a shell with its own tab bar does not need it.
///
/// `viewPadding` rather than `padding`: an open keyboard collapses `padding` to
/// zero and the spacing would jump.
EdgeInsets withSystemNavInset(BuildContext context, EdgeInsets base) => base
    .copyWith(bottom: base.bottom + MediaQuery.viewPaddingOf(context).bottom);
