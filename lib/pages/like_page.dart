import 'package:cativerse/data/likes_json.dart';
import 'package:cativerse/theme/colors.dart';
import 'package:flutter/material.dart';

class LikesPage extends StatefulWidget {
  @override
  _LikesPageState createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      bottomSheet: getFooter(),
      body: getBody(),
    );
  }

  Widget getBody() {
    var size = MediaQuery.of(context).size;
    return ListView(
      padding: EdgeInsets.only(bottom: 90),
      children: [
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            Text(
              "10 Likes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Top Picks",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 10),
        Divider(thickness: 0.8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: List.generate(likes_json.length, (index) {
              return Container(
                width: (size.width - 15) / 2,
                height: 250,
                child: Stack(
                  children: [
                    Container(
                      width: (size.width - 15) / 2,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: AssetImage(likes_json[index]['img']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      width: (size.width - 15) / 2,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            black.withOpacity(0.25),
                            black.withOpacity(0),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: likes_json[index]['active'] ? green : grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  likes_json[index]['active']
                                      ? "Recently Active"
                                      : "Offline",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        )
      ],
    );
  }

  Widget getFooter() {
    var size = MediaQuery.of(context).size;
    return Container(
      width: size.width,
      height: 90,
      child: Column(
        children: [
          Container(
            width: size.width - 70,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [yellow_one, yellow_two],
              ),
            ),
            child: Center(
              child: Text(
                "SEE WHO LIKES YOU",
                style: TextStyle(
                  fontSize: 18,
                  color: white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
