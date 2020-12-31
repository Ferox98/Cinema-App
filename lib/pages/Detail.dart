import 'dart:io';

import 'package:cinema/utils/Constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cinema/models/Movie.dart';
import 'dart:convert';
import 'dart:developer';
import 'package:path_provider/path_provider.dart';
import 'package:xml/xml.dart';
import 'package:cinema/models/SelectionDetails.dart';
import 'package:cinema/pages/Selector.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class Detail extends StatefulWidget {
  final String movieId;
  Detail({@required this.movieId});

  @override
  _DetailState createState() => _DetailState();
}

class _DetailState extends State<Detail> {

  Future<Movie> movie;
  Future<Map<String, List<String>>> schedule;
  String selectedDate;
  String selectedTime;

  void _changeSelectedDate(String date) {
    setState(() {
      selectedDate = date;
    });
  }

  void _changeSelectedTime(String time) {
    setState(() {
      selectedTime = time;
    });
  }

  /* This function fetched all the times and dates the current movie is airing at and stores
   the data on a Map for constant-time lookup */
  Future<Map<String, List<String>>> _fetchSchedule(Future<Movie> movie) async {
    Movie mov = await movie;
    Map<String, List<String>> scheduleMap = {};
    // fetch all days at which current movie is airing
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/schedule.xml');
    final document = await file.readAsString().then((value) => XmlDocument.parse(value));
    final schedule = document.findAllElements('movie');
    schedule.forEach((element) {
      List<dynamic> attributes = element.attributes;
      if (attributes[0].toString().contains(mov.title)) {
        String dateAttribute = attributes[2].toString();
        String timeAttribute = attributes[1].toString();
        String date = dateAttribute.substring(6, dateAttribute.length - 1);
        String time = timeAttribute.substring(6, timeAttribute.length - 1);
        if (scheduleMap[date] == null) {
          scheduleMap[date] = [time];
        }
        else {
          scheduleMap[date].add(time);
        }
      }
    });
    selectedDate = scheduleMap.entries.first.key;
    return scheduleMap;
  }

  // This function opens the ratings.xml file and saves the rating the user has given to this movie.
  void _setRating(String movie, double rating) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/ratings.xml');
    final document = await file.readAsString().then((value) => XmlDocument.parse(value));
    final ratingElements = document.findAllElements('rating');
    ratingElements.forEach((ratingElement) {
      if (ratingElement.getAttribute('movie').toString() == movie) {
        ratingElement.setAttribute('rate', rating.toString());
        return;
      }
    });
    file.writeAsString(document.toString());
  }

  // This function checks the ratings.xml file to see if the user has rated the selected movie previously.
  Future<double> _getRating(String movie) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/ratings.xml');
    final document = await file.readAsString().then((value) => XmlDocument.parse(value));
    final ratingElements = document.findAllElements('rating');
    double rating = -1.0;
    ratingElements.forEach((ratingElement) {
      if (ratingElement.getAttribute('movie').toString() == movie && ratingElement.getAttribute('rate').toString() != "unrated") {
        rating = double.parse(ratingElement.getAttribute('rate').toString());
        return rating;
      }
    });
    return rating;
  }

  /* This function displays the rating the user has given this movie if the user has rated it before.
     If the user has not rated the movie, he/she is urged to rate the movie */
  FutureBuilder _buildRating(String movie) {
    return FutureBuilder(
        future: _getRating(movie),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget> [
                  Text(snapshot.data == -1.0 ? 'Have you seen this movie? Give it a rating' : 'You have rated this movie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300)),
                  Padding(padding: EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0)),
                  RatingBar.builder(
                      initialRating: snapshot.data == -1.0? 0.0 : snapshot.data,
                      direction: Axis.horizontal,
                      itemCount: 5,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                          Icons.star,
                          color: Colors.amber
                      ),
                      itemSize: 20.0,
                      onRatingUpdate: (rating) {
                        _setRating(movie, rating);
                      }
                  ),
                  _buildPadding(),
                ]
            );
          }
          return Center(child: CircularProgressIndicator());
        }
    );
  }

  // This function fetches movie data from the IMDB database
  Future<Movie> _fetchMovie () async {
    final response = await http.get('http://omdbapi.com/?apikey=8213a572&i=${widget.movieId}');
    if (response.statusCode == 200) {
      Movie movie = Movie.fromJson(jsonDecode(response.body));
      return movie;
    }
    throw Exception('Failed to load movie');
  }

  @override
  void initState() {
    super.initState();
    movie = _fetchMovie();
    schedule = _fetchSchedule(movie);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          title: Center(
              child: Text('Now Showing', style: TextStyle(color: Colors.white))
          ),
          backgroundColor: Color.fromRGBO(78, 195, 237, 1.0),
        ),
        body: FutureBuilder(
            future: movie,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding (
                    padding: EdgeInsets.all(25.0),
                    child: SingleChildScrollView (
                        child: Column(
                          children: <Widget>[
                            _buildImage(snapshot),
                            _buildPadding(),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text(snapshot.data.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, ))
                                ]
                            ),
                            _buildPadding(),
                            _buildGeneralInfo(snapshot),
                            _buildPadding(),
                            Divider(),
                            _buildPadding(),
                            _buildHeader(snapshot),
                            _buildPadding(),
                            Row(
                                children: <Widget>[
                                  Expanded(
                                      child: Text(snapshot.data.plot, maxLines: 6, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300))
                                  )
                                ]
                            ),
                            _buildPadding(),
                            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[Text('Date', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))]),
                            _buildPadding(),
                            Container (
                                height: 100,
                                child: _buildSchedule()
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: <Widget>[
                                  Text('Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))
                                ]
                            ),
                            _buildPadding(),
                            Container(
                                height: 200,
                                child: FutureBuilder(
                                    future: schedule,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        log(selectedDate, name: 'loggers');
                                        return ListView(
                                            scrollDirection: Axis.vertical,
                                            children: snapshot.data[selectedDate].map<Widget>((time) =>
                                                FlatButton(
                                                    onPressed: () {_changeSelectedTime(time);},
                                                    color: time == selectedTime ? primaryColor : Colors.white,
                                                    child: Text(time, style: TextStyle(color: time == selectedTime? Colors.white : Colors.black)),
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(10.0),
                                                        side: BorderSide(color: primaryColor)
                                                    )
                                                )
                                            ).toList()
                                        );
                                      }
                                      return Center(child: CircularProgressIndicator());
                                    }
                                )
                            ),
                            _buildPadding(),
                            _buildRating(snapshot.data.title),
                            FlatButton(
                                onPressed: () {
                                  if (selectedTime != null) {
                                    SelectionDetails args = SelectionDetails(selectedDate: selectedDate, selectedTime: selectedTime, movie: snapshot.data.title);
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => Selector(args: args)));
                                  }
                                },
                                color: selectedTime == null ? Colors.grey : primaryColor,
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
                          ],
                        )
                    )
                );
              }
              return Center(child: CircularProgressIndicator());
            }
        )
    );
  }

  FutureBuilder _buildSchedule() {
    return FutureBuilder(
        future: schedule,
        builder: (context, snapshot)  {
          if (snapshot.hasData) {
            return ListView(
                scrollDirection: Axis.horizontal,
                children: snapshot.data.entries.map<Widget>((element) => Stack(
                    children: <Widget>[
                      IconButton(
                        iconSize: 80,
                        padding: EdgeInsets.all(8.0),
                        icon: Icon(
                          Icons.calendar_today_rounded,
                          color: element.key == selectedDate? primaryColor: Colors.grey,
                        ),
                        onPressed: () {
                          _changeSelectedDate(element.key);
                        },
                      ),

                      Positioned(
                          top: 18.0,
                          right: 35,
                          child: Text(element.key.substring(0, 3), style: TextStyle(fontSize: 14, color: Colors.white))
                      ),
                      Positioned(
                          top: 38,
                          right: 40,
                          child: Text(element.key.substring(8), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
                      ),
                      Positioned(
                          top: 60,
                          right: 36,
                          child: Text(element.key.substring(4, 7))
                      )
                    ]
                )
                ).toList()
            );
          }
          return Center(child: CircularProgressIndicator());
        }
    );
  }

  Padding _buildPadding() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 10, 0, 0)
    );
  }

  Row _buildHeader(AsyncSnapshot snapshot) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text('Synopsis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          // Expanded(),
          Wrap(
              spacing: 8.0,
              children: snapshot.data.genres.map<Widget>((genre) => new Chip(
                  label: Text(genre),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  )
              )).toList()
          )
        ]
    );
  }

  Row _buildGeneralInfo(AsyncSnapshot snapshot) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.star_border_outlined),
          Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
          Text(snapshot.data.rating),
          SizedBox(width: 30.0),
          Icon(Icons.access_time),
          Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
          Text(snapshot.data.runtime),
          SizedBox(width: 30.0),
          Icon(Icons.movie_creation_outlined),
          Padding(padding: EdgeInsets.fromLTRB(5, 0, 0, 0)),
          Text('3D')
        ]
    );
  }

  Column _buildImage(AsyncSnapshot snapshot) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Image.network(snapshot.data.poster_url, fit: BoxFit.cover)
          )
        ]
    );
  }
}