import 'dart:ui';

import 'package:flutter/material.dart';
import 'models/xela_toggle_models.dart';
import 'utils/flutter_switch.dart';
import 'xela_color.dart';

class XelaToggle extends StatefulWidget {

  final Widget? iconOn;
  final Widget? iconOff;
  final Function(bool) onToggle;
  final XelaToggleSize size;
  final Color onBackground;
  final Color offBackground;
  final Color circleOnColor;
  final Color circleOffColor;
  bool status;
  final Widget? content;


  XelaToggle({
    Key? key,
    this.iconOn,
    this.iconOff,
    required this.onToggle,
    this.size = XelaToggleSize.MEDIUM,
    this.onBackground = XelaColor.Blue3,
    this.offBackground = XelaColor.Gray11,
    this.circleOnColor = Colors.white,
    this.circleOffColor = Colors.white,
    this.status = false,
    this.content
  }) : super(key: key);

  @override
  _XelaToggleState createState() => _XelaToggleState();
}

class _XelaToggleState extends State<XelaToggle> {
  _XelaToggleState();

  @override
  Widget build(BuildContext context) {

    return Row(
      children: [
        widget.content != null ? Expanded(child: widget.content!) : Container(),
        FlutterSwitch(
          width: widget.size == XelaToggleSize.LARGE ? 56 : widget.size == XelaToggleSize.MEDIUM ? 48 : 32,
          height: widget.size == XelaToggleSize.LARGE ? 32 : widget.size == XelaToggleSize.MEDIUM ? 24 : 16,
          toggleSize: widget.size == XelaToggleSize.LARGE ? 24 : widget.size == XelaToggleSize.MEDIUM ? 20 : 14,
          value: widget.status,
          borderRadius: 100.0,
          padding: widget.size == XelaToggleSize.LARGE ? 4 : widget.size == XelaToggleSize.MEDIUM ? 2 : 1,
          showOnOff: false,
          onToggle: (val) {
            setState(() {
              widget.status = val;
              widget.onToggle(val);
            });
          },
          activeIcon: widget.iconOn,
          inactiveIcon: widget.iconOff,
          activeColor: widget.onBackground,
          inactiveColor: widget.offBackground,
          activeToggleColor: widget.circleOnColor,
          inactiveToggleColor: widget.circleOffColor,
        )
      ],
    );
  }
}
