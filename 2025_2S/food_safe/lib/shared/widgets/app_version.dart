import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../theme/color_schemes.dart';

class AppVersionWidget extends StatelessWidget {
  final Color? textColor;

  const AppVersionWidget({super.key, this.textColor});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (BuildContext context, AsyncSnapshot<PackageInfo> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          final PackageInfo packageInfo = snapshot.data!;
          return Text(
            'Versão ${packageInfo.version}/${packageInfo.buildNumber}',
            style: TextStyle(
              color: textColor ?? darkColorScheme.primary,
              fontSize: 10,
            ),
          );
        }
        return Container();
      },
    );
  }
}
