class Post {
  String postCreator; //the user who created the specific post
  String contents; //the text of the post
  List tags = []; //the tags which the user put on the post
  DateTime time; //the time at which the post was made
  List likes; //the amount of likes the post has recieved
  String id; //the unique id code for the post
  List comments; //list of all of the comments users have made about the post

  //constructor
  Post(
      {required this.postCreator,
      required this.contents,
      required this.tags,
      required this.time,
      required this.likes,
      required this.id,
      required this.comments});

  //returns whether or not the user has entered any tags onto the post
  bool hasTags() {
    return tags.isEmpty;
  }
}
