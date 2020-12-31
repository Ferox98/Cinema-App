class Movie {
  final String title;
  final String runtime;
  final String poster_url;
  final String rating;
  final String plot;
  final List<String> genres;

  Movie({this.title, this.runtime, this.poster_url, this.rating, this.plot, this.genres});

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
        title: json['Title'],
        runtime: json['Runtime'],
        poster_url: json['Poster'],
        rating: json['imdbRating'],
        plot: json['Plot'],
        genres: json['Genre'].toString().split(',')
    );
  }
}