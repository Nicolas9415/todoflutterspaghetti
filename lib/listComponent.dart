import 'package:flutter/material.dart';

class ListElement extends StatefulWidget {
  final String text;
  final OnChange onChangeEvent;
  final bool active;
  final DisplayInfo displayInfo;
  final String id;
  final String location;
  final int position;
  final String img;
  final String date;

  ListElement(
      {this.img,
      ValueKey key,
      this.id,
      this.location,
      this.position,
      this.text,
      this.active,
      this.onChangeEvent,
      this.displayInfo,
      this.date})
      : super(key: key);

  @override
  ListElementState createState() => new ListElementState();
}

class ListElementState extends State<ListElement> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext ctx) {
    bool _checked = widget.active;
    return InkWell(
      onTap: () => widget.displayInfo(this.widget),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          height: 75,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.0),
            ),
            elevation: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 13.0),
                    child: Container(
                      width: 150,
                      child: Text(
                        widget.text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Theme(
                  data: ThemeData(
                    unselectedWidgetColor: Colors.black12,
                  ),
                  child: Transform.scale(
                    scale: 1.5,
                    child: Center(
                      child: Checkbox(
                        tristate: true,
                        value: _checked,
                        activeColor: Color.fromRGBO(92, 168, 224, 1),
                        onChanged: (_) => {
                          setState(() => _checked = !_checked),
                          widget.onChangeEvent(widget.key),
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef OnChange = void Function(ValueKey key);
typedef DisplayInfo = void Function(ListElement key);
