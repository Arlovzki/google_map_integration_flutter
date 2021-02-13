import 'package:flutter/material.dart';

class CustomOutlineButton extends StatelessWidget {
  final EdgeInsets padding;
  final Color buttonColor;
  final Widget child;

  const CustomOutlineButton({
    Key key,
    this.padding,
    this.buttonColor,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: buttonColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: ButtonTheme(
          minWidth: 309.0,
          height: 52.0,
          child: OutlineButton(
            onPressed: () {},
            color: buttonColor,
            highlightedBorderColor: buttonColor,
            splashColor: buttonColor.withOpacity(0.1),
            borderSide: BorderSide(
              width: 2.0,
              color: buttonColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
