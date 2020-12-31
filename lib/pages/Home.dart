import 'dart:io';
import 'dart:convert';
import 'dart:developer';

import 'package:cinema/models/Movie.dart';
import 'package:cinema/utils/Constants.dart';
import 'package:cinema/pages/Detail.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  /* This function checks the application documents directory to see if the ratings.xml and schedule.xml files exist.
     If they doesn't, it copies the contents of the assets/ratings.xml and assets/schedule.xml file there */
  void _saveSchedule() async {
    final directory = await getApplicationDocumentsDirectory();
    var file = File('${directory.path}/ratings.xml');
    if (!file.existsSync()) {
      var document = await rootBundle.loadString('assets/ratings.xml').then((value) => XmlDocument.parse(value));
      file.writeAsString(document.toString());
    }
    file = File('${directory.path}/schedule.xml');
    if (!file.existsSync()) {
      var document = await rootBundle.loadString('assets/schedule.xml').then((value) => XmlDocument.parse(value));
      file.writeAsString(document.toString());
    }
  }

  /* This function fetches movie data from the IMDB database
   */
  Future<List<Movie>> _fetchMovies() async {
    List<Movie> res = [];
    for (String movie_id in MOVIES) {
      final response = await http.get('http://omdbapi.com/?apikey=$apiKey&i=$movie_id');
      if (response.statusCode == 200) {
        Movie movie = Movie.fromJson(jsonDecode(response.body));
        res.add(movie);
      }
      else {
        throw Exception('Failed to load movie');
      }
    }
    return res;
  }

  // Runtimes are provided in minutes from the IMDB API. This function converts the minutes to HH:MM format
  String _calculateRuntimeHours(String runtime) {
    String minuteString = runtime.substring(0, 3);
    int minutes = int.parse(minuteString);
    double eval = minutes / 60;
    int hour = eval.toInt();
    int min = minutes % (hour * 60);
    String result = '${hour.toString()}h ${min.toString()}m';
    return result;
  }

  @override
  void initState() {
    super.initState();
    _saveSchedule();
  }

  FutureBuilder<List<Movie>> generateCards() {
    var size = MediaQuery.of(context).size;

    final double itemHeight = (size.height - kToolbarHeight - 140) / 2;
    final double itemWidth = size.width / 2;

    return FutureBuilder(future: _fetchMovies(), builder: (context, snapshot) {
      if (snapshot.hasData) {
        return OrientationBuilder(builder: (context, orientation) {
          return GridView.builder(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220.0, mainAxisSpacing: 10.0, childAspectRatio: orientation == Orientation.portrait ? (itemWidth / itemHeight) : 0.6),
              itemCount: snapshot.data.length,

              itemBuilder: (context, index) {
                return (
                    InkWell(
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Detail(movieId: MOVIES[index]))
                          );
                        },
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                  width: 180,
                                  height: 220,
                                  child: ClipRRect (
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: Image.network(
                                        '${snapshot.data[index].poster_url}',
                                        fit: BoxFit.cover
                                    ),
                                  )
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                              ),
                              Text('${snapshot.data[index].title}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Padding(
                                  padding: EdgeInsets.fromLTRB(0, 10, 0, 0)
                              ),
                              Text(_calculateRuntimeHours(snapshot.data[index].runtime), style: TextStyle(color: Colors.blueGrey))
                            ]
                        )
                    )
                );
              });
        });
      }
      else {
        log('Error: ${snapshot.error}');
        return Center(child: CircularProgressIndicator());
      }
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text('Now Showing', style: TextStyle(color: Colors.white)),
          ),
          backgroundColor: primaryColor,
        ),
        body: Padding(
            padding: EdgeInsets.all(16.0),
            child: SafeArea(
                child: generateCards()
            )
        )
    );
  }
}