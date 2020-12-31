import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cinema/models/ConfirmationTicket.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cinema/utils/Constants.dart';
import 'package:xml/xml.dart';

class Confirmation extends StatefulWidget {
  final ConfirmationTicket ticket;
  Confirmation({@required this.ticket});
  @override
  _ConfirmationState createState() => _ConfirmationState();
}

class _ConfirmationState extends State<Confirmation> {

  GlobalKey _globalKey = GlobalKey();
  bool rendering;

  @override
  void initState() {
    super.initState();
    rendering = false;
  }

  Text _printSchedule() {
    final map = {
      'Mon': 'MONDAY', 'Tue': 'TUESDAY', 'Wed': 'WEDNESDAY', 'Thu': 'THURSDAY', 'Fri': 'FRIDAY', 'Sat': 'SATURDAY', 'Sun': 'Sunday', 'Jan': 'January'
    };
    String month = widget.ticket.date.substring(4, 7);
    String date = widget.ticket.date.substring(8);
    return Text(map[month] + ' ' + date + ', 2020', style: TextStyle(fontSize: 16));
  }

  // This function converts the Widgets currently being displayed into PNG format and saves them to the gallery.
  void _capturePng() async {
    RenderRepaintBoundary boundary =
    _globalKey.currentContext.findRenderObject();
    // check recursively until paint is finished
    // if (boundary.debugNeedsPaint) {
    //   await Future.delayed(const Duration(milliseconds: 20));
    //   _capturePng();
    //   return;
    // }
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData byteData =
    await image.toByteData(format: ui.ImageByteFormat.png);
    var pngBytes = byteData.buffer.asUint8List();

    if (await Permission.storage.request().isGranted) {
      final res = await ImageGallerySaver.saveImage(pngBytes);
      Fluttertoast.showToast(msg: 'Image Saved', toastLength: Toast.LENGTH_LONG);
    }
  }

  //
  void _saveSchedule() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/schedule.xml');
    final document = await file.readAsString().then((value) => XmlDocument.parse(value));
    final schedule = document.findAllElements('movie');
    print('${widget.ticket.date}, ${widget.ticket.time}');
    schedule.forEach((element) {
      if (element.getAttribute('date') == widget.ticket.date && element.getAttribute('time') == widget.ticket.time) {
        for (var seat in widget.ticket.seats) {
          final child = XmlElement(XmlName('reserved'));
          child.setAttribute('seat', seat);
          print('adding child: ${child.toString()}');
          element.children.add(child);
        }
      }
    });
    file.writeAsString(document.toString()).then((value) => print(value.toString()));
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
        key: _globalKey,
        child: Scaffold (
            appBar: AppBar (
              iconTheme: IconThemeData(
                color: Colors.white, //change your color here
              ),
              backgroundColor: Color.fromRGBO(78, 195, 237, 1.0),
              title: Center(
                  child: Text(
                      'Seat Selector',
                      style: TextStyle(color: Colors.white)
                  )
              ),
            ),
            body: Padding (
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView (
                    child: Column (
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          _buildPadding(0.0, 8.0, 0.0, 0.0),
                          Center(child: Text('Cinema Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                          Padding(padding: EdgeInsets.fromLTRB(100.0, 16.0, 100.0, 0.0), child: Divider(thickness: 2,)),
                          _buildPadding(0.0, 8.0, 0.0, 0.0),
                          Text(widget.ticket.movie, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Container(
                              height: 325,
                              child: Image(image: AssetImage('assets/images/qrcode.png'))
                          ),
                          Padding(
                              padding: EdgeInsets.fromLTRB(40.0, 0.0, 40.0, 0.0),
                              child: Column(
                                  children: <Widget>[
                                    Divider(thickness: 2),
                                    _buildPadding(0.0, 8.0, 0.0, 0.0),
                                    Row(
                                        children: <Widget>[
                                          Expanded(
                                              child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16))
                                          ),
                                          Text('Time', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))
                                        ]
                                    ),
                                    _buildPadding(0.0, 4.0, 0.0, 0.0),
                                    Row(
                                        children: <Widget>[
                                          Expanded(
                                              child: _printSchedule()
                                          ),
                                          Text(widget.ticket.time, style: TextStyle(fontSize: 16))
                                        ]
                                    ),
                                    _buildPadding(0.0, 16.0, 0.0, 0.0),
                                    Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: Text('Cinema Hall', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                                          ),
                                          Text('Seat', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16))
                                        ]
                                    ),
                                    _buildPadding(0.0, 8.0, 0.0, 0.0),
                                    Row(
                                        children: <Widget>[
                                          Expanded(
                                              child: Text('A', style: TextStyle(fontSize: 16))
                                          ),
                                          ...widget.ticket.seats.map<Widget>((seat) =>
                                              Container(
                                                  padding: EdgeInsets.fromLTRB(8.0, 0.0, 0.0, 0.0),
                                                  child: Text(seat, style: TextStyle(fontSize: 16))
                                              )
                                          ).toList()
                                        ]
                                    ),
                                    _buildPadding(0.0, 8.0, 0.0, 0.0),
                                    Divider(thickness: 2),
                                    Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: <Widget>[
                                          Text('Notice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text('1. Keep this receipt safe and private', style: TextStyle(fontSize: 14)),
                                          Text('2. Do not share or duplicate this receipt', style: TextStyle(fontSize: 14)),
                                          Text('3. The above code is valid for only one use', style: TextStyle(fontSize: 14)),
                                        ]
                                    ),

                                  ]
                              )
                          ),
                          _buildPadding(0.0, 8.0, 0.0, 0.0),
                          FlatButton(
                              onPressed: () {
                                _capturePng();
                                _saveSchedule();
                              },
                              color: primaryColor,
                              height: 45,
                              child: Row(
                                  children: <Widget>[
                                    Expanded(
                                        child: Center(
                                            child: Text('Save Ticket', style: TextStyle(color: Colors.white, fontSize: 16))
                                        )
                                    ),
                                  ]
                              )
                          )
                        ]
                    )
                )
            )
        )
    );
  }

  Padding _buildPadding(double left, double top, double right, double bottom) =>
      Padding(padding: EdgeInsets.fromLTRB(left, top, right, bottom));
}