import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:locator/pages/online_users.dart';
import 'package:locator/utils/google_sign_in.dart';

class ProfilePage extends StatelessWidget {
  final FirebaseUser user;

  ProfilePage(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Material(
            elevation: 1,
            child: Container(
              color: Colors.white,
              height: 236,
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      trailing: InkWell(
                          onTap: () {
                            SignInHelper.signOutGoogle();
                          },
                          child: Text("Logout")),
                      leading: IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Hero(
                      tag: 'profile_url',
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: Colors.black54,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(56),
                          child: Image.network(
                            user.photoUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    Text(
                      user.displayName,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                    )
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: OnlineUsers())
        ],
      ),
    );
  }
}
