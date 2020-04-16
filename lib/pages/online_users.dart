import 'package:flutter/material.dart';

import '../demo_data.dart';

class OnlineUsers extends StatefulWidget {
  @override
  _OnlineUsersState createState() => _OnlineUsersState();
}

class _OnlineUsersState extends State<OnlineUsers> {
  double sheetHeight;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    sheetHeight = 256;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Container(
        height: MediaQuery.of(context).size.height*.35,
        child: Column(
          children: <Widget>[
            Container(
              color: Theme.of(context).primaryColor,
              child: ListTile(
                dense: true,
                title: Text(
                  "Online Users",
                  style: TextStyle(color: Colors.white),
                ),
                trailing: InkWell(
                  onTap: (){
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                  physics: ClampingScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: DemoData.data.length,
                  itemBuilder: (context, index) {
                    return ListTile(
//                          contentPadding: EdgeInsets.symmetric(horizontal: 2),
                      title: Text(DemoData.data[index].name),
                      leading: Container(
                        child: CircleAvatar(
                          radius: 16,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              child: Image.network(
                                  DemoData.data[index].profileImgUrl),
                            ),
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          InkWell(
                            child: Container(
                              child: Text(
                                "Ask",
                              ),
                            ),
                            onTap: () {},
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          InkWell(
                            child: Container(
                              child: Text(
                                "Share",
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              ),
                            ),
                            onTap: () {},
                          ),
                        ],
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
