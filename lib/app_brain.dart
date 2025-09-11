import 'dart:collection';
import 'package:crypt/crypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppBrain {
  String loggedUser = ''; //stores who the app is currently logged in as
  List postList = []; //stores all of the posts to be displayed
  List userList =
      []; //stores a list of all of the users to be displayed when on the search page
  List followedUsers =
      []; //stores all of the users followed by the logged in user
  String searchTerm =
      ''; //stores the term which is being searched for in the search page

  //when a user tries to create a new account, this is ran to see if the user is able to.
  Future<String> validateNewAccount(String username, String password) async {
    String valid = 'error validating account';

    //check that username is less than or equal to 10 characters and not left empty
    if (username.length <= 10 && username.isNotEmpty) {
      //check that password is more than or equal to 8 characters
      if (password.length >= 8) {
        //check that password has a capital letter or special character
        for (var i = password.length - 1; i >= 0; i--) {
          if (password[i] == password[i].toUpperCase()) {
            print(password[i]);
            print(password[i].toUpperCase());
            valid = 'true';
            break;
          }
        }
        if (valid != 'true') {
          valid = 'password needs capital letter or a special character!';
        }
      } else {
        valid = 'password needs to be at least 8 characters long!';
      }
    } else {
      valid =
          'username cannot be over 10 characters long, and cannot be left blank';
    }

    //check to see if the username is already taken
    if (username != '') {
      final DocumentReference<Map<String, dynamic>> account =
          FirebaseFirestore.instance.collection('users').doc(username);

      await account.get().then((DocumentSnapshot doc) => {
            if (doc.exists)
              {valid = 'username already taken! please try a different one!'}
          });
    }

    return valid;
  }

  //create a new user on the database
  Future createUser(String username, String password) async {
    //hash password
    final hashedPassword = Crypt.sha256(password, salt: 'abcdefg');
    //instance the correct database position
    final user = FirebaseFirestore.instance.collection('users').doc(username);
    //create the user JSON file
    final info = {
      'username': username,
      'password': hashedPassword.toString(),
      'following': []
    };
    //add the JSON file to the database
    await user.set(info);
  }

  //login to an existing account if possble, if not return why
  Future<String> logIn(String username, String password) async {
    Map<String, dynamic> data;

    String returnVal = '';
    print('logging in as $username with pw $password');

    //get the account the user wants to log into
    final DocumentReference<Map<String, dynamic>> account =
        FirebaseFirestore.instance.collection('users').doc(username);
    //next two lines fix an occaisional bug.
    await FirebaseFirestore.instance.disableNetwork();
    await FirebaseFirestore.instance.enableNetwork();

    await account.get().then(
      (DocumentSnapshot doc) {
        //check if user exists
        if (doc.exists) {
          data = doc.data() as Map<String, dynamic>;
          //hash the password the user has given and see if it is the same as the one on the database
          String hashedPassword =
              Crypt.sha256(password, salt: 'abcdefg').toString();
          if (data['password'] == hashedPassword) {
            returnVal = 'correct';
            loggedUser = data['username'];
          } else {
            returnVal = 'wrong';
          }
        } else {
          returnVal = 'no user';
        }
      },
      onError: (e) {
        returnVal = 'error: $e';
      },
    );
    return returnVal;
  }

  //write a new post to the database
  Future<bool> createPost(contents, tags) async {
    bool returnVal = false;
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(loggedUser)
        .collection('posts')
        .doc(); //instance the database and postition to be used
    await ref.set({
      //set the data
      'contents': contents,
      'tags': tags,
      'time': DateTime.now(),
      'user': loggedUser,
      'id': ref.id,
      'comments': [],
      'likes': []
    }).then((value) {
      returnVal = true;
    });
    return returnVal;
  }

  //get all of the correct posts to be displayed to the user from the database
  Future<List<dynamic>> getPosts() async {
    List following = []; //list of all of the users that are followed
    postList = []; //empty list to be filled with posts
    final u = FirebaseFirestore.instance.collection('users').doc(loggedUser);
    //get all of the accouns that the logged user follows and add them to the list 'following'
    await u.get().then((value) {
      Map<String, dynamic> data = value.data() as Map<String, dynamic>;
      following = data['following'];
      following.add(loggedUser);
    });

    //for each user in the following array get all of the posts from that user
    for (var i in following) {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(i)
          .collection('posts');
      QuerySnapshot snap = await ref.get();
      final userPosts = snap.docs.map((doc) => doc.data()).toList();
      //add each post to the database
      for (var i in userPosts) {
        postList.add(i);
      }
    }
    return sortPosts(postList);
  }

  //perform a sort on the posts so they can be displayed in a reverse chronilogical order
  List sortPosts(List posts) {
    int length = posts.length;
    //bubble sort the posts
    for (int i = 0; i < length - 1; i++) {
      for (int j = 0; j < length - i - 1; j++) {
        int first = posts[j]['time'].microsecondsSinceEpoch;
        int second = posts[j + 1]['time'].microsecondsSinceEpoch;
        if (first < second) {
          LinkedHashMap<String, dynamic> temp = posts[j];
          posts[j] = posts[j + 1];
          posts[j + 1] = temp;
        }
      }
    }
    return [posts];
  }

  //append a comment to the correct post on the database
  Future addComment(String postId, String commentAuthor, String comment,
      String postCreator) async {
    //get the post to add the comment to
    final targetPost = FirebaseFirestore.instance
        .collection('users')
        .doc(postCreator)
        .collection('posts')
        .doc(postId);

    //create the comment map to be sent to the database
    var newComment = {
      'comment': comment,
      'time': DateTime.now(),
      'user': commentAuthor
    };

    // add the comment
    targetPost.update({
      'comments': FieldValue.arrayUnion([newComment])
    });
  }

  //linear search for seeing if a user has liked a post
  bool userInList(List list, String user) {
    //return value will return whether or not user is in list
    bool returnVal = false;
    //for each item in the list
    for (int i = 0; i < list.length; i++) {
      //if the user is found, set return val to true and end the loop
      if (list[i] == user) {
        returnVal = true;
        break;
      }
    }
    return returnVal;
  }

  //add a like to a post on the database
  Future likePost(String postId, String postCreator) async {
    //get the post which should be liked
    final targetPost = FirebaseFirestore.instance
        .collection('users')
        .doc(postCreator)
        .collection('posts')
        .doc(postId);
    //add the logged in user to the list of user who have liked the post
    targetPost.update({
      'likes': FieldValue.arrayUnion([loggedUser])
    });
  }

  //remove a like from a post on the database
  Future unLikePost(String postId, String postCreator) async {
    //get the post which should be unliked
    final targetPost = FirebaseFirestore.instance
        .collection('users')
        .doc(postCreator)
        .collection('posts')
        .doc(postId);
    //remove the logged in user from the list of all of the user who have liked the post
    targetPost.update({
      'likes': FieldValue.arrayRemove([loggedUser])
    });
  }

  //get all of the users to be displayed on the search page
  Future<List> getUsers() async {
    userList = [];
    final ref = FirebaseFirestore.instance.collection('users');
    QuerySnapshot snap = await ref.get();
    final users = snap.docs.map((e) => e.data()).toList();
    for (var i in users) {
      userList.add(i);
    }

    return [userList];
  }

  //make the logged in account follow a user
  Future followUser(String user) async {
    //create a reference to the necessary place in the database to update the data
    final ref = FirebaseFirestore.instance.collection('users').doc(loggedUser);
    //append the new user to the following array
    ref.update({
      'following': FieldValue.arrayUnion([user])
    });
  }

  //make the logged in account unfollow a user
  Future unFollowUser(String user) async {
    //create a reference to the necessary place in the database to update the data
    final ref = FirebaseFirestore.instance.collection('users').doc(loggedUser);
    //remove the required user from the following array
    ref.update({
      'following': FieldValue.arrayRemove([user])
    });
  }
}
