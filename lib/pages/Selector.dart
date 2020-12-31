import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cinema/models/ConfirmationTicket.dart';
import 'package:cinema/models/SelectionDetails.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:developer';
import 'package:cinema/utils/Constants.dart';
import 'Confirmation.dart';

class Selector extends StatefulWidget {
  final SelectionDetails args;
  Selector({@required this.args});
  @override
  _SelectorState createState() => _SelectorState();
}

class _SelectorState extends State<Selector> {

  String dropdownValue = "1";
  List<int> selectedSeats = [];
  int totalPayable = 75;

  // This function adds the currently selected seat to the selectedSeats list if it can be selected
  void _reserveSeat(int index) {
    if (selectedSeats.contains(index)) {
      setState(() {
        selectedSeats.remove(index);
      });
      return;
    }
    if (selectedSeats.length >= int.parse(dropdownValue)) {
      return;
    }
    setState(() {
      selectedSeats.add(index);
    });
  }

  // This function converts a seat number (like "9A") into an integer index
  int _calculateIndex(String seat) {
    int col = 12 - int.parse(seat.substring(0, 1));
    int row = seat.codeUnitAt(1) - 65; // subtract from ASCII value of A
    int index = 120 - (row * 12 + col) - 12;
    return index;
  }

  // This function converts an integer index assigned to a seat back to its seat number;
  String _calculateSeat(int index) {
    double val = index / 12;
    int row = val.toInt();
    int occupied = row * 12;
    int col = index - occupied;
    String res = col.toString() + String.fromCharCode(73 - row);
    return res;
  }

  // This function parses schedule.xml to identify all seats that had been previously reserved
  Future<List<int>> _fetchReserved() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/schedule.xml');
    final document = await file.readAsString().then((value) => XmlDocument.parse(value));
    final schedule = document.findAllElements('movie');
    String selectedDate = widget.args.selectedDate;
    String selectedTime = widget.args.selectedTime;
    List<String> reserved = [];
    List<int> reservedIndices = [];
    schedule.forEach((element) {
      List<dynamic> attributes = element.attributes;
      if (element.getAttribute('date').toString() == selectedDate && element.getAttribute('time').toString() == selectedTime) {
        element.children.forEach((child) {
          if (child.toString().contains('reserved')) {
            String seat = child.getAttribute('seat');
            reserved.add(seat);
          }
        });
        for (String seat in reserved) {
          int seatIndex = _calculateIndex(seat);
          reservedIndices.add(seatIndex);
        }
        return reservedIndices;
      }
    });
    return reservedIndices;
  }

  Text _printSchedule() {
    final map = {
      'Mon': 'MONDAY', 'Tue': 'TUESDAY', 'Wed': 'WEDNESDAY', 'Thu': 'THURSDAY', 'Fri': 'FRIDAY', 'Sat': 'SATURDAY', 'Sun': 'Sunday', 'Jan': 'JANUARY'
    };
    String weekday = widget.args.selectedDate.substring(0, 3);
    String date = widget.args.selectedDate.substring(8);
    String time = widget.args.selectedTime;
    return Text(map[weekday] + ', ' + date + ' | ' + time, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            iconTheme: IconThemeData(
              color: Colors.white, //change your color here
            ),
            backgroundColor: Color.fromRGBO(78, 195, 237, 1.0),
            title: Center(child: Text('Seat Selector', style: TextStyle(color: Colors.white)))
        ),
        body: Padding(
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
            child: SingleChildScrollView(
                child: Container(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Card (
                              elevation: 5,
                              margin: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                              child: Container(
                                  height: 120,
                                  child: Column(
                                      children: <Widget>[
                                        _buildPadding(24),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Text(widget.args.movie, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                                            ]
                                        ),
                                        _buildPadding(12),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              Text('Schedule Selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300))
                                            ]
                                        ),
                                        Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: <Widget>[
                                              _printSchedule()
                                            ]
                                        )
                                      ]
                                  )
                              )
                          ),
                          _buildPadding(20),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text('Hall 1: Block A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
                              ]
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text('Tap on your preferred seat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300))
                              ]
                          ),
                          FutureBuilder(
                              future: _fetchReserved(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Container(
                                    transform: Matrix4.translationValues(0, 20, 1),
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8, right: 20),
                                      child: GridView.count(
                                        crossAxisSpacing: 10,
                                        shrinkWrap: true,
                                        crossAxisCount: 12,
                                        mainAxisSpacing: 10,
                                        children: List.generate(120, (index) {
                                          if (index % 12 == 0 || index >= 109) {
                                            return Center(child: Text(nextText(index), style: TextStyle(fontSize: 16)));
                                          }
                                          return Center(
                                            child: RaisedButton(
                                              color: snapshot.data.contains(index) ? Colors.black26 : selectedSeats.contains(index) ? primaryColor : Colors.white,
                                              onPressed: () {
                                                if (!snapshot.data.contains(index)) {
                                                  _reserveSeat(index);
                                                }
                                              },
                                              shape: RoundedRectangleBorder(side: BorderSide(color: Colors.black), borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  );
                                }
                                return Center(child: CircularProgressIndicator());
                              }
                          ),

                          _buildPadding(40.0),
                          _buildLegend(),
                          Padding (
                              padding: EdgeInsets.all(24.0),
                              child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black, width: 0.5),
                                      borderRadius: BorderRadius.circular(20.0)
                                  ),
                                  child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          height: 50,
                                          child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              //crossAxisAlignment: CrossAxisAlignment.center,
                                              children: <Widget>[
                                                Container(
                                                    width: 50,
                                                    height: 35,
                                                    child: Text('TICKET QTY', overflow: TextOverflow.ellipsis, maxLines: 2)
                                                ),
                                                _buildPaddingLeft(16.0),
                                                _buildDropdown(context),
                                                _buildPaddingLeft(16.0),
                                                VerticalDivider(color: Colors.black, thickness: 0.5),
                                                _buildPaddingLeft(16.0),
                                                Container(
                                                    width: 60,
                                                    height: 35,
                                                    child: Text('TOTAL PAYABLE', overflow: TextOverflow.ellipsis, maxLines: 2)
                                                ),
                                                _buildPaddingLeft(16.0),
                                                Text(
                                                    totalPayable.toString(),
                                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)
                                                ),
                                              ]
                                          ),
                                        ),
                                      ]
                                  )
                              )
                          ),
                          FlatButton(
                              onPressed: () {
                                if (selectedSeats.length > 0) {
                                  List<String> seats = [];
                                  for (var seat in selectedSeats) {
                                    seats.add(_calculateSeat(seat));
                                  }
                                  ConfirmationTicket ticket = ConfirmationTicket(movie: widget.args.movie, date: widget.args.selectedDate, time: widget.args.selectedTime, seats: seats);
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => Confirmation(ticket: ticket)));
                                }
                              },
                              color: primaryColor,
                              height: 50,
                              child: Row(
                                  children: <Widget>[
                                    Expanded(
                                        child: Text('Continue to seat selector', style: TextStyle(color: Colors.white, fontSize: 15))
                                    ),
                                    Icon(Icons.arrow_right_alt_outlined, color: Colors.white)
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

  Padding _buildPaddingLeft(double val) => Padding(padding: EdgeInsets.fromLTRB(val, 0.0, 0.0, 0.0));

  @override
  Widget _buildDropdown(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 0,
      style: TextStyle(color: Colors.black),
      onChanged: (String newValue) {
        setState(() {
          dropdownValue = newValue;
          totalPayable = UNIT_TICKET_PRICE * int.parse(dropdownValue);
        });
      },
      items: <String>['1', '2', '3', '4']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300)),
        );
      }).toList(),
    );
  }

  Row _buildLegend() {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              width: 25,
              height: 25,
              child: RaisedButton(
                  onPressed: () {},
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.black), borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                  color: Colors.white
              )
          ),
          Padding(padding: EdgeInsets.fromLTRB(4.0, 0.0, 0.0, 0.0)),
          Text('Available', style: TextStyle(fontSize: 14)),
          SizedBox(width: 32.0),
          Container(
            width: 25,
            height: 25,
            child: RaisedButton(
                onPressed: () {},
                shape: RoundedRectangleBorder(side: BorderSide(color: Colors.black), borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                color: Colors.grey.shade600
            ),
          ),

          Padding(padding: EdgeInsets.fromLTRB(4.0, 0.0, 0.0, 0.0)),
          Text('Unavailable', style: TextStyle(fontSize: 14)),
          SizedBox(width: 32.0),
          Container(
              width: 25,
              height: 25,
              child: RaisedButton(
                  onPressed: () {},
                  shape: RoundedRectangleBorder(side: BorderSide(color: Colors.black), borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                  color: primaryColor
              )
          ),
          Padding(padding: EdgeInsets.fromLTRB(4.0, 0.0, 0.0, 0.0)),
          Text('Your Selections', style: TextStyle(fontSize: 14)),
        ]
    );
  }

  String nextText(int index) {
    var hash = {
      0: 'I', 12: 'H', 24: 'G', 36: 'F', 48: 'E', 60: 'D', 72: 'C', 84: 'B', 96: 'A', 108: '', 109: '1', 110: '2', 111: '3', 112: '4', 113: '5', 114: '6', 115: '7', 116: '8', 117: '9', 118: '10', 119: '11'
    };
    return hash[index];
  }

  Padding _buildPadding(double top) => Padding(padding: EdgeInsets.fromLTRB(0, top, 0.0, 0.0));
}
