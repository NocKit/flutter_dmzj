import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parallax/flutter_parallax.dart';
import 'package:flutterdmzj/database/database.dart';
import 'package:flutterdmzj/http/http.dart';
import 'package:flutterdmzj/view/login_page.dart';

import 'ComicViewer.dart';

class ComicDetailPage extends StatefulWidget {
  String id = '';

  ComicDetailPage(this.id);

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _ComicDetailPage(id);
  }
}

class _ComicDetailPage extends State<ComicDetailPage> {
  String title = '加载中';
  String id = '';
  String cover = 'http://manhua.dmzj.com/css/img/mh_logo_dmzj.png?t=20131122';
  String author = '加载中';
  String types = '加载中';
  int hotNum = 0;
  int subscribeNum = 0;
  String description = '加载中...';
  bool error = false;
  String updateDate = '';
  String status = '加载中';
  List chapters = <Widget>[];
  bool login = false;
  bool sub = false;
  bool loading = false;
  String uid = '';

  _ComicDetailPage(this.id);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadComic();
    getIfSubscribe();
  }

  @override
  void deactivate() {
    super.deactivate();
    var bool = ModalRoute.of(context).isCurrent;
    if (bool) {
      Future.delayed(Duration(milliseconds: 200)).then((e) {
        loadComic();
        getIfSubscribe();
      });
    }
  }

  void loadComic() async {
    try {
      CustomHttp http = CustomHttp();
      var response = await http.getComicDetail(id);
      DataBase dataBase = DataBase();
      var last = await dataBase.getHistory(id);
      if (response.statusCode == 200 && mounted) {
        setState(() {
          title = response.data['title'];
          cover = response.data['cover'];
          List temp = <String>[];
          response.data['authors'].forEach((value) {
            temp.add(value['tag_name']);
          });
          author = temp.join('/');
          temp.clear();
          response.data['types'].forEach((value) {
            temp.add(value['tag_name']);
          });
          types = temp.join('/');
          hotNum = response.data['hot_num'];
          subscribeNum = response.data['subscribe_num'];
          description = response.data['description'];
          var date = DateTime.fromMicrosecondsSinceEpoch(
              response.data['last_updatetime'] * 1000000);
          updateDate = '${date.year}-${date.month}-${date.day}';
          temp.clear();
          response.data['status'].forEach((value) {
            temp.add(value['tag_name']);
          });
          status = temp.join('/');

          chapters.clear();
          List chapterData = response.data['chapters'];
          for (var item in chapterData) {
            var chapterList = <Widget>[];
            var chapterIdList = item['data'].map((map) {
              return map['chapter_id'].toString();
            }).toList();

            for (var chapter in item['data']) {
              if (last.first.length > 0 &&
                  chapter['chapter_id'].toString() == last.first[0]['value']) {
                chapterList.add(Container(
                  width: 120,
                  margin: EdgeInsets.fromLTRB(3, 0, 3, 0),
                  child: OutlineButton(
                    child: Text(
                      chapter['chapter_title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.blue),
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ComicViewer(id, chapter['chapter_id'].toString(),
                            chapterIdList);
                      }));
                    },
                  ),
                ));
              } else {
                chapterList.add(Container(
                  width: 120,
                  margin: EdgeInsets.fromLTRB(3, 0, 3, 0),
                  child: OutlineButton(
                    child: Text(
                      chapter['chapter_title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ComicViewer(id, chapter['chapter_id'].toString(),
                            chapterIdList);
                      }));
                    },
                  ),
                ));
              }
            }
            chapters.add(Column(
              children: <Widget>[
                Text(item['title']),
                Divider(),
                Wrap(
                  children: chapterList,
                )
              ],
            ));
          }
        });
      }
    } catch (e) {
      print(e);
      setState(() {
        error = true;
      });
    }
  }

  getIfSubscribe() async {
    if (mounted) {
      setState(() {
        loading = true;
      });
    }
    DataBase dataBase = DataBase();
    bool loginState = await dataBase.getLoginState();
    if (mounted) {
      setState(() {
        login = loginState;
      });
    }
    if (login) {
      uid = await dataBase.getUid();
      CustomHttp http = CustomHttp();
      var response = await http.getIfSubscribe(id, uid);
      if (response.statusCode == 200 && mounted && response.data['code'] == 0) {
        setState(() {
          sub = true;
        });
      }
    }
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error) {
      return Scaffold(
        appBar: AppBar(
          title: Text('好像出了点问题！'),
        ),
        body: Center(
          child: Text('漫画找不到了！'),
        ),
      );
    }
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: <Widget>[
            Builder(
              builder: (context) {
                return FlatButton(
                  child: Icon(
                    sub ? Icons.favorite : Icons.favorite_border,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    if (loading) {
                      Scaffold.of(context).showSnackBar(
                          new SnackBar(content: Text('订阅信息还在加载中!')));
                    } else if (!login) {
                      Scaffold.of(context).showSnackBar(new SnackBar(
                        content: Text('请先登录!'),
                        action: SnackBarAction(
                          label: '去登录',
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return LoginPage();
                            }));
                          },
                        ),
                      ));
                    } else {
                      CustomHttp http = CustomHttp();
                      if (sub) {
                        http.cancelSubscribe(id, uid).then((response) {
                          if (response.statusCode == 200 &&
                              response.data['code'] == 0 &&
                              mounted) {
                            setState(() {
                              sub = false;
                            });
                          }
                        });
                      } else {
                        http.addSubscribe(id, uid).then((response) {
                          if (response.statusCode == 200 &&
                              response.data['code'] == 0 &&
                              mounted) {
                            setState(() {
                              sub = true;
                            });
                          }
                        });
                      }
                    }
                  },
                );
              },
            )
          ],
        ),
        body: Scrollbar(
          child: SingleChildScrollView(
            child: new Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Parallax.inside(
                        child: Image(
                            image: CachedNetworkImageProvider(cover,
                                headers: {'referer': 'http://images.dmzj.com'}),
                            fit: BoxFit.cover),
                        mainAxisExtent: 200.0,
                      ),
                    )
                  ],
                ),
                DetailCard(title, updateDate, status, author, types, hotNum,
                    subscribeNum, description),
                Card(
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Column(children: chapters),
                )
              ],
            ),
          ),
        ));
  }
}

class DetailCard extends StatelessWidget {
  final String title;
  final String updateDate;
  final String status;
  final String author;
  final String types;
  final int hotNum;
  final int subscribeNum;
  final String description;

  DetailCard(this.title, this.updateDate, this.status, this.author, this.types,
      this.hotNum, this.subscribeNum, this.description);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Card(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Padding(
          padding: EdgeInsets.fromLTRB(4, 2, 4, 10),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Text(
                    '最后更新：$updateDate  $status',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
              Divider(
                color: Colors.black,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.supervisor_account,
                          color: Colors.grey,
                        ),
                        Text(
                          author,
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.category,
                          color: Colors.grey,
                        ),
                        Text(
                          types,
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    ),
                  )
                ],
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.whatshot,
                          color: Colors.grey,
                        ),
                        Text('$hotNum')
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.favorite,
                          color: Colors.grey,
                        ),
                        Text('$subscribeNum')
                      ],
                    ),
                  )
                ],
              ),
              Divider(),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(description),
                  )
                ],
              )
            ],
          ),
        ));
  }
}