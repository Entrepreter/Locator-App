import 'package:flutter/material.dart';
import 'package:locator/main.dart';

class ErrorPage extends StatelessWidget {
  final String errorMsg;

  ErrorPage(this.errorMsg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.80,
                height: 156,
                child: Image.asset('assets/images/location_permission.png'),
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.80,
                child: Text(
                  errorMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300),
                ),
              ),
              FlatButton(
                onPressed: () {
                  RestartWidget.restartApp(context);
                },
                child: Text(
                  'Retry',
                  style: TextStyle(
                      color: Theme.of(context).primaryColor, fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
