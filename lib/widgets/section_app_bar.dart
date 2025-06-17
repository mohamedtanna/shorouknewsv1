import 'package:flutter/material.dart';

class SectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final IconThemeData? iconTheme;
  final double elevation;

  const SectionAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = false,
    this.bottom,
    this.backgroundColor,
    this.iconTheme,
    this.elevation = 4.0,
  }) : super(key: key);

  @override
  Size get preferredSize {
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight + 10.0);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomHeight = bottom?.preferredSize.height ?? 0;
    return AppBar(
      title: title,
      actions: actions,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      backgroundColor: backgroundColor,
      iconTheme: iconTheme,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(bottomHeight + 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bottom != null) bottom!,
            Container(
              color: Colors.grey[300],
              height: 10.0,
            ),
          ],
        ),
      ),
    );
  }
}
