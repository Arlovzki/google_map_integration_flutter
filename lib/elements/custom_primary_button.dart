import 'package:flutter/material.dart';

class CustomPrimaryButton extends StatelessWidget {
  final EdgeInsets padding;
  final Color buttonColor;
  final Widget child;
  final Function onPressed;

  const CustomPrimaryButton({
    Key key,
    this.padding,
    this.buttonColor,
    this.child,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ButtonTheme(
        minWidth: 309.0,
        height: 52.0,
        child: RaisedButton(
          onPressed: onPressed,
          elevation: 1.0,
          color: buttonColor,
          splashColor: Color(0xFFC4C4C4).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: child,
        ),
      ),
    );
  }
}
