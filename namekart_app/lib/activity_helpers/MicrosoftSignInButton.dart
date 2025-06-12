// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:msal_auth/msal_auth.dart';
//
// import 'UIHelpers.dart';
//
// class MicrosoftSignInButton extends StatefulWidget {
//   @override
//   _MicrosoftSignInButtonState createState() => _MicrosoftSignInButtonState();
// }
//
// class _MicrosoftSignInButtonState extends State<MicrosoftSignInButton> {
//   bool _isLoading = false;
//   late final Future<SingleAccountPca> _pcaFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     // Notice: no tenantId here
//     _pcaFuture = SingleAccountPca.create(
//       clientId: 'c671954e-7f6e-4db7-91f9-08fa9eca986b',
//       androidConfig: AndroidConfig(
//         configFilePath: 'assets/msal_config.json',
//         redirectUri: 'msalc671954e-7f6e-4db7-91f9-08fa9eca986b://auth',
//       ),
//     );
//   }
//
//   Future<void> _signIn() async {
//     setState(() => _isLoading = true);
//     try {
//       final pca = await _pcaFuture;
//       final result = await pca.acquireToken(
//         scopes: ['User.Read'],
//         prompt: Prompt.login,
//       );
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Signed in as: ${result.account?.username ?? 'Unknown'}')),
//       );
//     } on MsalException catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Sign-in failed: ${e.toString()}')),
//       );
//       print(e.toString());
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _isLoading ? null : _signIn,
//       child: Container(
//         padding: EdgeInsets.all(15),
//         decoration: const BoxDecoration(
//           color: Colors.black,
//           borderRadius: BorderRadius.all(Radius.circular(10)),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (_isLoading)
//               const SizedBox(
//                 height: 24,
//                 width: 24,
//                 child: CircularProgressIndicator(color: Colors.white),
//               )
//             else ...[
//               Image.asset(
//                 'assets/images/login_screen_images/microsoft.png',
//                 height: 20.sp,
//                 width: 20.sp,
//               ),
//               const SizedBox(width: 12),
//               text(text:'Sign in with Microsoft',
//                   size: 12,
//                   color: Colors.white,
//                   fontWeight: FontWeight.w300),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
