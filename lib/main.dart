import 'package:flutter/material.dart';
import 'package:todoflutterspaghetti/listComponent.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:geocoder/geocoder.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';

Color azulClaro = Color.fromRGBO(92, 168, 224, 1);
FirebaseMessaging firebaseMessaging = FirebaseMessaging();

void main() => runApp(new MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyApp(),
    ));

class MyApp extends StatefulWidget {
  @override
  createState() => MyAppState();
}

TextEditingController _textFieldController = TextEditingController();

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  String location;
  String _image;
  String date;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    fillTasks();
    _getCurrentLocation();
    super.initState();
    firebaseMessaging.configure(
      onLaunch: (Map<String, dynamic> msg) {
        debugPrint('launch');
        return;
      },
      onResume: (Map<String, dynamic> msg) {
        debugPrint('resume');
        return;
      },
      onMessage: (Map<String, dynamic> msg) {
        debugPrint('message');
        return;
      },
    );

    firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(sound: true, alert: true, badge: true));
    firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      debugPrint('ios');
    });

    firebaseMessaging.getToken().then((onValue) {
      debugPrint(onValue);
    });

    firebaseMessaging.subscribeToTopic('push');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _tasks.forEach((task) => {
            if (task.id == null)
              {
                _postData(task),
              }
            else
              {_updateTask(task)}
          });
    } else if (state == AppLifecycleState.resumed) {
      fillTasks();
    }
  }

  var _tasks = [];
  bool view = true;

  Future<List<ListElement>> _getAll() async {
    var data = await http.get('https://backendthesis.herokuapp.com/data');
    var jsonData = json.decode(data.body);

    List<ListElement> elements = [];
    for (var u in jsonData) {
      ListElement data = ListElement(
        id: u["_id"],
        text: u['task'],
        onChangeEvent: _onChangeEvent,
        active: u['active'],
        position: u['position'],
        location: u['location'],
        key: ValueKey(u['task']),
        img: u['picture'],
        date: u['date'],
      );

      elements.add(data);
    }
    elements..sort((a, b) => a.position.compareTo(b.position));
    return elements;
  }

  void _postData(ListElement element) {
    debugPrint(element.text);
    http.post('https://backendthesis.herokuapp.com/data', body: {
      'task': element.text,
      "active": "${element.active}",
      "position": "${element.position}",
      "location": "${element.location}",
      "picture": "${element.img}",
      "date": "${element.date}"
    });
  }

  void _updateTask(ListElement element) {
    http.put('https://backendthesis.herokuapp.com/data/${element.id}', body: {
      'task': element.text,
      "active": "${element.active}",
      "position": "${element.position}",
      "location": "${element.location}",
      "picture": "${element.img}",
      "date": "${element.date}"
    });
  }

  void _deleteData(String id, ValueKey key) {
    setState(() {
      _tasks = _tasks.where((task) => task.key != key).toList();
    });
    http.delete('https://backendthesis.herokuapp.com/data/$id');
  }

  fillTasks() {
    _getAll().then((e) => {
          setState(() {
            _tasks = e;
          })
        });
  }

  void _onChangeEvent(ValueKey key) {
    setState(() {
      _tasks = [
        ..._tasks.map((item) {
          return item.key == key
              ? ListElement(
                  id: item.id,
                  text: item.text,
                  active: !item.active,
                  key: ValueKey(item.text),
                  onChangeEvent: _onChangeEvent,
                  position: item.position,
                  location: item.location,
                  img: item.img,
                  date: item.date,
                )
              : item;
        })
      ];
    });
  }

  List<ListElement> _getTasks(bool condition) {
    var list = _tasks
        .where((item) => item.active != condition)
        .map((item) => ListElement(
              id: item.id,
              key: ValueKey(item.text),
              active: item.active,
              text: item.text,
              onChangeEvent: _onChangeEvent,
              displayInfo: _displayInfo,
              position: item.position,
              location: item.location,
              img: item.img,
              date: item.date,
            ));

    return list.toList();
  }

  void _changeView(val) {
    setState(() {
      view = val;
    });
  }

  void _dragEvent(DragUpdateDetails event) {
    final dir = event.primaryDelta;

    setState(() {
      if (dir <= -7)
        view = false;
      else if (dir >= 7) view = true;
    });
  }

  void _reorderItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final ListElement x = _tasks.removeAt(oldIndex);
      _tasks.insert(newIndex, x);
      _tasks = _tasks
          .asMap()
          .map((index, item) => MapEntry(
              index,
              ListElement(
                id: item.id,
                key: ValueKey(item.text),
                active: item.active,
                text: item.text,
                onChangeEvent: _onChangeEvent,
                displayInfo: _displayInfo,
                position: index,
                location: item.location,
                img: item.img,
                date: item.date,
              )))
          .values
          .toList();
    });

    _tasks.forEach((task) => _updateTask(task));
  }

  _emptyText() {
    String text = view
        ? "You have no pending tasks"
        : "You haven't compleated any task yet";
    return [
      Text(
        text,
        key: Key('empty'),
        style: TextStyle(color: azulClaro, fontSize: 20),
      )
    ].toList();
  }

  void _displayInfo(ListElement element) async {
    String status = element.active ? "Compleated" : "Not yet compleated";
    return showDialog(
      context: this.context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Task Details',
            textAlign: TextAlign.center,
          ),
          titleTextStyle: TextStyle(
            color: azulClaro,
            fontSize: 40,
          ),
          content: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            width: MediaQuery.of(context).size.width * 0.75,
            child: ListView(
              children: <Widget>[
                Text(
                  "Task",
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 30),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(element.text,
                      style: TextStyle(fontSize: 20, color: Colors.grey[500])),
                ),
                Divider(
                  color: azulClaro,
                  thickness: 2,
                ),
                Text(
                  "Status",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('$status',
                      style: TextStyle(fontSize: 20, color: Colors.grey[500])),
                ),
                Divider(
                  color: azulClaro,
                  thickness: 2,
                ),
                Text(
                  "Location",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('${element.location}',
                      style: TextStyle(fontSize: 20, color: Colors.grey[500])),
                ),
                Divider(
                  color: azulClaro,
                  thickness: 2,
                ),
                Text(
                  "Date due",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: element.date == null || element.date == 'null'
                      ? new Text('No date added',
                          style:
                              TextStyle(fontSize: 20, color: Colors.grey[500]))
                      : new Text('${element.date}',
                          style:
                              TextStyle(fontSize: 20, color: Colors.grey[500])),
                ),
                Divider(
                  color: azulClaro,
                  thickness: 2,
                ),
                Text(
                  "Image",
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
                Container(
                  width: 200,
                  height: 200,
                  child: new Center(
                      child: element.img == null || element.img == 'null'
                          ? new Text('No Image to Show ')
                          : new Image.file(File(element.img))),
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new FlatButton(
                        child: new Text(
                          'Back',
                          style: TextStyle(color: azulClaro),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      new FlatButton(
                        color: Colors.red,
                        child: new Text(
                          'DELETE',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _deleteData(element.id, element.key);
                        },
                      ) // button 2
                    ])
              ],
            ),
          ),
        );
      },
    );
  }

  Future _displayDialog(BuildContext context) async {
    _getCurrentLocation();
    return showDialog(
      context: this.context,
      builder: (context) {
        return AlertDialog(
          title: Text('Please enter your task details'),
          content: Container(
            height: MediaQuery.of(context).size.height / 2,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Text('Task description'),
                  TextField(
                    controller: _textFieldController,
                    decoration: InputDecoration(hintText: "Task description"),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Text("Add an image"),
                        IconButton(
                          icon: Icon(Icons.camera_alt),
                          onPressed: _chooseCamera,
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Text("When is the task due?"),
                        IconButton(
                          icon: Icon(Icons.date_range),
                          onPressed: _selectDate,
                        )
                      ],
                    ),
                  )
                ]),
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _textFieldController.clear();
              },
            ),
            new FlatButton(
              child: _textFieldController.text.isNotEmpty
                  ? new Text(
                      'Confirm',
                    )
                  : new Text(
                      'Confirm',
                      style: TextStyle(color: Colors.grey),
                    ),
              onPressed: () {
                if (_textFieldController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  setState(() {
                    _tasks = [
                      ..._tasks,
                      ListElement(
                        text: _textFieldController.text,
                        onChangeEvent: _onChangeEvent,
                        active: false,
                        key: ValueKey(_textFieldController.text),
                        position: _tasks.length + 1,
                        location: location,
                        img: _image,
                        date: date,
                      )
                    ];
                  });
                  setState(() {
                    _image = null;
                  });
                }
                _textFieldController.clear();
                setState(() {
                  _image = null;
                  date = null;
                });
              },
            )
          ],
        );
      },
    );
  }

  _selectDate() {
    DatePicker.showDateTimePicker(
      this.context,
      showTitleActions: true,
      minTime: DateTime.now(),
      onChanged: (e) {
        setState(() {
          date = e.toString();
        });
      },
      onConfirm: (e) {
        setState(() {
          date = e.toString();
        });
      },
      currentTime: DateTime.now(),
    );
  }

  _chooseCamera() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Please choose between camera or gallery'),
            content: Container(
              height: MediaQuery.of(context).size.height * 0.1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Text('Camera'),
                      IconButton(
                        icon: Icon(Icons.camera_alt),
                        onPressed: () => picker(true, context),
                      )
                    ],
                  ),
                  Column(
                    children: <Widget>[
                      Text('Gallery'),
                      IconButton(
                        icon: Icon(Icons.photo),
                        onPressed: () => picker(false, context),
                      )
                    ],
                  )
                ],
              ),
            ),
            actions: <Widget>[
              new FlatButton(
                child: new Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  _getLocationName(Position pos) async {
    final coordinates = new Coordinates(pos.latitude, pos.longitude);
    var addresses = await Geocoder.google('YOUR-API-KEY')
        .findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    setState(() {
      location = "${first.addressLine}";
    });
  }

  _getCurrentLocation() async {
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      _getLocationName(position);
    }).catchError((e) {
      throw e;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter todo app',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        key: _scaffoldKey,
        floatingActionButton: FloatingActionButton(
            backgroundColor: azulClaro,
            tooltip: 'Add a new task',
            child: Transform.scale(scale: 1.7, child: Icon(Icons.add)),
            onPressed: () => _displayDialog(context)),
        body: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  InkWell(
                    onTap: () => _changeView(true),
                    child: Text(
                      'To-Do',
                      style: TextStyle(
                          color: view ? Colors.black : Colors.grey,
                          fontSize: 35,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 30.0,
                      width: 2.0,
                      color: azulClaro,
                      margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                    ),
                  ),
                  InkWell(
                    onTap: () => _changeView(false),
                    child: Text(
                      'Done',
                      style: TextStyle(
                          color: view ? Colors.grey : Colors.black,
                          fontSize: 35,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              indent: 20,
              endIndent: 20,
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails e) => _dragEvent(e),
                child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) =>
                        _reorderItems(oldIndex, newIndex),
                    children: _getTasks(view).isNotEmpty
                        ? _getTasks(view)
                        : _emptyText()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  picker(bool action, BuildContext context) async {
    File img = action
        ? await ImagePicker.pickImage(source: ImageSource.camera)
        : await ImagePicker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      Navigator.of(context).pop();
      setState(() {
        _image = img.path;
      });
    }
  }
}
