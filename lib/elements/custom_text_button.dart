import 'package:flutter/material.dart';

class CustomTextButton extends StatelessWidget {
  final Color textColor;
  final Widget child;

  const CustomTextButton({
    Key key,
    this.textColor,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('Tapped');
      },
      child: child,
    );
  }
}
