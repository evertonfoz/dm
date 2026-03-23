import 'package:flutter/material.dart';
import '../../../theme/color_schemes.dart';

class ProfileSelectButton extends StatelessWidget {
  final Function() onPressed;
  final String text;

  const ProfileSelectButton({
    super.key,
    required this.onPressed,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(40)),
              ),
              backgroundColor: lightColorScheme.secondaryContainer,
              foregroundColor: lightColorScheme.primary,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  // fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        if (MediaQuery.sizeOf(context).height > 1000)
          const SizedBox(height: 15),
      ],
    );
  }
}
