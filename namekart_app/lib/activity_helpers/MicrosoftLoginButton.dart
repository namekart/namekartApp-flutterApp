import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bounceable/flutter_bounceable.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:msal_auth/msal_auth.dart';
import 'package:namekart_app/activity_helpers/UIHelpers.dart';
import 'package:namekart_app/database/HiveHelper.dart';
import 'package:path/path.dart';

import 'GlobalVariables.dart';

class MicrosoftLoginButton extends StatelessWidget {
  const MicrosoftLoginButton({super.key});

  static const String tenantId =
      'eba2c098-631c-4978-8326-5d25c2d09ca5'; // Your Azure AD tenant ID

  void _showSnackBar(BuildContext context, String message,
      {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 1),
        action: SnackBarAction(
          label: 'Close',
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _signInWithMicrosoft(BuildContext context) async {
    final msalAuth = await SingleAccountPca.create(
      clientId: 'c671954e-7f6e-4db7-91f9-08fa9eca986b',
      androidConfig: AndroidConfig(
        configFilePath: 'assets/msal_config.json',
        redirectUri: GlobalProviders().redirectUri,
      ),
    );

    try {
      final result = await msalAuth.acquireToken(scopes: ['User.Read']);
      print('Access Token:${result.account.username} ${result.accessToken} ');

      _showSnackBar(context, "✅ Logged in successfully", success: true);

      HiveHelper.delete("account~user~details");
      HiveHelper.addDataToHive("account~user~details", result.account.username!,
          {"default": "true"});

      GlobalProviders.userId = result.account.username!;
      GlobalProviders.loginToken = result.account;

      Navigator.pushReplacementNamed(context, 'home',
          arguments: {"isAdmin": true});

      Haptics.vibrate(HapticsType.success);
    } catch (e) {
      print(e);
      print(e);
      _showSnackBar(context, "✅ MSAL Sign-in failed $e", success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Bounceable(
          onTap: () => _signInWithMicrosoft(context),
          child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: Colors.black12, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/login_screen_images/microsoft.png",
                    width: 20,
                    height: 20,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  text(
                      text: 'Sign In with Microsoft',
                      color: Colors.white,
                      size: 12.sp,
                      fontWeight: FontWeight.bold),
                ],
              ))),
    );
  }
}
