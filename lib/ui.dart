import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:social_media_app/main.dart';
import 'post.dart';

//this is the main colour used for UI elements throughout the app
Color mainColor = const Color.fromARGB(255, 166, 115, 218);

//the main app class, all of the other widgets are used by this one
class SocialMediaApp extends StatelessWidget {
  const SocialMediaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media App',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
              primary: mainColor,
              secondary: const Color.fromARGB(255, 195, 168, 221))),
      home: const LoginPage(),
    );
  }
}

//the first page displayed to the user, lets them choose between loggin in or creating an account
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  //this is made a variable so it can be changed to a loading indicator when appropriate
  Widget loginButtonChild = const Text('login');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
            child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: ListView(
            children: [
              const SizedBox(height: 180),
              LoginTextField(name: 'username', controller: usernameController),
              const SizedBox(height: 10),
              LoginTextField(
                  name: 'password',
                  hidePw: true,
                  controller: passwordController),
              const SizedBox(height: 10),
              ElevatedButton(
                  onPressed: () {
                    setState(() {
                      //show that the app is loading by adding a progress indicator to the button
                      loginButtonChild =
                          const CircularProgressIndicator(color: Colors.white);
                    });
                    //check that the user has entered the correct input
                    if (usernameController.text == '') {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => const ErrorBox(
                              errorText: 'please enter a username!'));
                      loginButtonChild = const Text('login');
                    } else if (passwordController.text == '') {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => const ErrorBox(
                              errorText: 'please enter a password!'));
                      loginButtonChild = const Text('login');
                    } else {
                      //if all is good, attempt to login
                      appBrain
                          .logIn(
                              usernameController.text, passwordController.text)
                          .then((value) {
                        print('---------------------$value---------------');
                        if (value == 'wrong') {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) => const ErrorBox(
                                  errorText: 'incorrect password!'));
                        } else if (value == 'no user') {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  const ErrorBox(errorText: 'no user exists!'));
                        } else if (value == 'error') {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) => const ErrorBox(
                                  errorText:
                                      'there was an error, please try again.'));
                        } else if (value == 'correct') {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MainPage()));
                        }
                        setState(() {
                          loginButtonChild = const Text('login');
                        });
                      });
                    }
                  },
                  style:
                      ElevatedButton.styleFrom(minimumSize: const Size(0, 45)),
                  child: loginButtonChild),
              const SizedBox(height: 10),
              LoginButton(
                  name: 'create account',
                  onpress: (() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CreateAccountPage()),
                    );
                  }))
            ],
          ),
        )),
      ),
    );
  }
}

//the main page, which will eventually show the user their feed
class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        //the search button which will take users to the search page
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            appBrain.searchTerm = '';
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const followPage()));
          },
          backgroundColor: mainColor,
          child: const Icon(
            Icons.search,
          ),
        ),
        body: SafeArea(
          //future builder, will display a loading indicator until all posts have been loaded
          child: FutureBuilder(
            future: appBrain.getPosts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator()));
              } else if (snapshot.connectionState == ConnectionState.done) {
                return Feed(posts: appBrain.postList);
              } else {
                return Text('state: ${snapshot.connectionState}');
              }
            },
          ),
        ));
  }
}

//the create account page, which can be navigated to from the login page and lets users create an account
class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({Key? key}) : super(key: key);

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Widget createAccountChild = const Text('create');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: ListView(
            children: [
              const SizedBox(
                height: 180,
              ),
              LoginTextField(
                name: 'new username',
                controller: usernameController,
              ),
              const SizedBox(height: 10),
              LoginTextField(
                  name: 'new password',
                  hidePw: true,
                  controller: passwordController),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    createAccountChild =
                        const CircularProgressIndicator(color: Colors.white);
                  });
                  appBrain
                      .validateNewAccount(
                          usernameController.text, passwordController.text)
                      .then((value) {
                    if (value == 'true') {
                      appBrain
                          .createUser(
                              usernameController.text, passwordController.text)
                          .then((value) => Navigator.pop(context));
                    } else {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              ErrorBox(errorText: value.toString()));
                      setState(() {
                        createAccountChild = const Text('create');
                      });
                    }
                  });
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 45)),
                child: createAccountChild,
              ),
            ],
          ),
        ),
      )),
    );
  }
}

//the feed widget, which contains a scrollable list which contains posts and the create post UI.
class Feed extends StatefulWidget {
  List posts;
  Feed({Key? key, required this.posts}) : super(key: key);

  @override
  State<Feed> createState() => _FeedState();
}

class _FeedState extends State<Feed> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 17),
      itemCount: widget.posts.length + 3,
      itemBuilder: (context, index) {
        if (index == 0) {
          //put the create post card at the top of the feed
          return const CreatePost();
        } else if (index == 1) {
          //put the refresh button as the second thing in the feed
          return Container(
            alignment: Alignment.topLeft,
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainPage(),
                    ));
              },
              icon: const Icon(Icons.refresh),
              color: Colors.grey,
            ),
          );
        } else if (1 < index && index < widget.posts.length + 2) {
          //create the post object to be passed
          Post post = Post(
              postCreator: widget.posts[index - 2]['user'],
              contents: widget.posts[index - 2]['contents'],
              tags: widget.posts[index - 2]['tags'],
              time: widget.posts[index - 2]['time'].toDate(),
              likes: widget.posts[index - 2]['likes'],
              id: widget.posts[index - 2]['id'],
              comments: widget.posts[index - 2]['comments']);
          //pass the post object into a postCard so it can be diplayed
          return PostCard(post: post);
        } else {
          //add a sized box at the end so the floating action button does not get in the way of the comment button
          return const SizedBox(
            height: 65,
          );
        }
      },
    );
  }
}

//the button used on the login/create account pages
class LoginButton extends StatelessWidget {
  final String? name;
  final VoidCallback onpress; //what the button should do when pressed
  const LoginButton({Key? key, this.name, required this.onpress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onpress,
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 45)),
      child: Text('$name'),
    );
  }
}

//the text field used on the login/create account pages
class LoginTextField extends StatelessWidget {
  final String? name;
  final bool
      hidePw; //boolean to determine whether or not the text should be hidden
  final TextEditingController controller;
  const LoginTextField(
      {Key? key, this.name, this.hidePw = false, required this.controller})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: hidePw,
      decoration: InputDecoration(
          border: const OutlineInputBorder(), labelText: '$name'),
    );
  }
}

//the alert box that is shown to the user when an error occurs
class ErrorBox extends StatelessWidget {
  final String errorText;
  const ErrorBox({Key? key, required this.errorText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('error'),
      content: Text(errorText),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('ok'))
      ],
    );
  }
}

//shown to users at the top of their feed, lets them create posts.
class CreatePost extends StatefulWidget {
  const CreatePost({Key? key}) : super(key: key);

  @override
  State<CreatePost> createState() => _CreatePostState();
}

class _CreatePostState extends State<CreatePost> {
  final tagController = TextEditingController();
  final contentsController = TextEditingController();

  List<Widget> tagsList =
      []; //holds the widgets which will show the tags the user has set
  List<String> tagsContents = []; //holds in string form all of the tags

  Widget createBttnChild = const Icon(Icons
      .send); //the icon in the create post button. can later be changed to a loading indicator.

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        color: Colors.grey[200],
      ),
      child: Center(
          child: Column(
        children: [
          TextField(
            controller: contentsController,
            minLines: 3,
            maxLines: 5,
            maxLength:
                256, //limit the characters which the user can input in the main post contents field
            decoration: const InputDecoration(
                labelText: 'new post',
                border: OutlineInputBorder(borderSide: BorderSide.none),
                counterText: ''),
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              SizedBox(
                  width: 240,
                  child: TextField(
                    controller: tagController,
                    maxLength:
                        8, //limit the amount of characters which a user can input in the tag field
                    decoration: InputDecoration(
                        counterText: '',
                        suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                //check that the user has not entered more than three tags before adding anouther
                                if (tagsList.length <= 2 &&
                                    tagController.text != '') {
                                  tagsList.add(PostTag(
                                      tagText: tagController
                                          .text)); //add the tag widget so the user can see it
                                  tagsContents.add(tagController
                                      .text); //add the text of the tag
                                  tagController.text = '';
                                }
                              });
                            },
                            icon: const Icon(Icons.add)),
                        labelText: 'tags ',
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none)),
                  )),
              const SizedBox(width: 10),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          //show to the user that the app is sending the post
                          createBttnChild = const CircularProgressIndicator(
                              color: Colors.white);
                        });
                        //make sure the user cannot send a blank post
                        if (contentsController.text.isEmpty) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) => const ErrorBox(
                                  errorText: 'post cant be blank!'));
                          setState(() {
                            createBttnChild = const Icon(Icons.send);
                          });
                        } else {
                          await appBrain
                              .createPost(contentsController.text, tagsContents)
                              .then((value) {
                            //check that the creation of the post was successful
                            if (value == true) {
                              //change the loading widget back to the send icon
                              setState(() {
                                createBttnChild = const Icon(Icons.send);
                                const snackbar = SnackBar(
                                  content: Text('post created!'),
                                  backgroundColor:
                                      Color.fromARGB(255, 166, 115, 218),
                                );
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(snackbar);
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MainPage(),
                                    ));
                              });
                              //empty out the tags + contents which the user has inputed is it has now been written to the database
                              contentsController.text = '';
                              tagController.text = '';
                              tagsContents = [];
                              tagsList = [];
                            } else {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) => const ErrorBox(
                                      errorText:
                                          'there was an error creating a post.'));
                              setState(() {
                                createBttnChild = const Icon(Icons.send);
                              });
                            }
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(10, 50)),
                      child: createBttnChild))
            ],
          ),
          const SizedBox(
            height: 1,
          ),
          Row(
            children: [
              Row(
                children: tagsList,
              ),
              tagsList.isEmpty //if there are no tags, dont display the clear tags button
                  ? const SizedBox(height: 2)
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          tagsList = [];
                          tagsContents = [];
                        });
                      },
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[500],
                      ))
            ],
          )
        ],
      )),
    );
  }
}

class PostTag extends StatelessWidget {
  final String tagText;
  const PostTag({super.key, required this.tagText});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        //the actual tag
        Container(
          width: 70,
          height: 30,
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: mainColor),
          child: Center(
            child: Text(
              tagText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        //sized box to space out the tags when placed next to each other
        const SizedBox(width: 2)
      ],
    );
  }
}

class PostCard extends StatefulWidget {
  final Post post;

  PostCard({Key? key, required this.post}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final TextEditingController commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //sized box to seperate the posts
        const SizedBox(
          height: 10,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            color: Colors.grey[200],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.post.postCreator,
                    style: TextStyle(
                        color: mainColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),
                  const Spacer(),
                  Text(
                    widget.post.time.toString().substring(0, 16),
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(widget.post.contents),
              const SizedBox(
                height: 8,
              ),
              Row(
                children: [
                  for (var i in widget.post.tags) PostTag(tagText: i),
                  const Spacer(),
                  LikeButtonNum(
                    post: widget.post,
                    initVal: appBrain.userInList(
                        widget.post.likes, appBrain.loggedUser),
                  )
                ],
              ),
              //this column will display all of the comments that the post has
              Column(
                children: [
                  //for each comment add it to the columns' childeren (reversed so it is ordered correct)
                  for (var i in widget.post.comments.reversed)
                    CommentCard(
                      comment: i,
                    )
                ],
              ),
              //UI for adding a new comment to the post
              Row(
                children: [
                  SizedBox(
                    width: 255,
                    child: TextField(
                      maxLength: 25,
                      controller: commentController,
                      decoration: const InputDecoration(
                          labelText: 'new comment',
                          border:
                              OutlineInputBorder(borderSide: BorderSide.none),
                          counterText: ''),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                      onPressed: () {
                        if (commentController.text.isEmpty) {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) => const ErrorBox(
                                  errorText:
                                      'you cant enter a blank comment!!'));
                        } else {
                          //add the comment to the post
                          appBrain.addComment(
                              widget.post.id,
                              appBrain.loggedUser,
                              commentController.text,
                              widget.post.postCreator);
                          commentController.text = '';
                          const snackbar = SnackBar(
                            content: Text('comment sent!'),
                            backgroundColor: Color.fromARGB(255, 166, 115, 218),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(snackbar);
                        }
                      },
                      icon: Icon(
                        Icons.send,
                        color: Colors.grey.shade600,
                      ))
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

//this is the UI for what comments should look like under posts
class CommentCard extends StatelessWidget {
  LinkedHashMap<String, dynamic> comment;
  CommentCard({Key? key, required this.comment}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              comment['user'],
              style: TextStyle(
                  color: mainColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Spacer(),
            Text(comment['time'].toDate().toString().substring(0, 16),
                style: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold))
          ],
        ),
        const SizedBox(
          height: 3,
        ),
        Text(comment['comment']),
        const SizedBox(
          height: 5,
        )
      ],
    );
  }
}

class LikeButtonNum extends StatefulWidget {
  final Post post;
  final bool initVal;
  const LikeButtonNum({Key? key, required this.post, required this.initVal})
      : super(key: key);

  @override
  State<LikeButtonNum> createState() => _LikeButtonNumState();
}

class _LikeButtonNumState extends State<LikeButtonNum> {
  late bool liked = widget.initVal;
  late int likesNum = widget.post.likes.length;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(likesNum.toString()),
        //if the user has liked the post, displayed a filled like button, if not display an unfiled one.
        (liked)
            ? IconButton(
                onPressed: () {
                  appBrain.unLikePost(widget.post.id, widget.post.postCreator);
                  setState(() {
                    liked = !liked;
                    likesNum--;
                  });
                },
                icon: Icon(
                  Icons.favorite,
                  color: mainColor,
                ))
            : IconButton(
                onPressed: () {
                  appBrain.likePost(widget.post.id, widget.post.postCreator);
                  setState(() {
                    liked = !liked;
                    likesNum++;
                  });
                },
                icon: Icon(
                  Icons.favorite_border,
                  color: mainColor,
                ))
      ],
    );
  }
}

//page for following users
class followPage extends StatefulWidget {
  const followPage({Key? key}) : super(key: key);

  @override
  State<followPage> createState() => _FollowPageState();
}

class _FollowPageState extends State<followPage> {
  TextEditingController searchUser = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                //the search box which can be used to find users
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20))),
                  child: TextField(
                    controller: searchUser,
                    decoration: InputDecoration(
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              appBrain.searchTerm = searchUser.text;
                            });
                          },
                          icon: Icon(
                            Icons.send,
                            color: Colors.grey[600],
                          ),
                        ),
                        border: const OutlineInputBorder(
                            borderSide: BorderSide.none),
                        labelText: 'search for user'),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                    height: 520,
                    //load of of the correct users and then display them
                    child: FutureBuilder(
                        future: appBrain.getUsers(),
                        builder: ((context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: SizedBox(
                                    height: 100,
                                    width: 100,
                                    child: CircularProgressIndicator()));
                          } else if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return ListOfUsers(
                              userList: appBrain.userList,
                            );
                            ;
                          } else {
                            return Text('state: ${snapshot.connectionState}');
                          }
                        })))
              ],
            ),
          ),
        ));
  }
}

//this widget displays the users which can be followed/unfollowed on the search page
class ListOfUsers extends StatelessWidget {
  List userList;
  ListOfUsers({Key? key, required this.userList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List showUsers = []; //list that will contain all of the users to be shown
    //if the search term is not blank, add users that username contain the search term to showUsers
    if (appBrain.searchTerm != '') {
      for (var i in userList) {
        if (i['username'].toString().contains(appBrain.searchTerm)) {
          showUsers.add(i);
        }
      }
      //if the search term is not blank, just show all of the users
    } else {
      showUsers = userList;
    }

    //return the list to be shown on the app
    return ListView.builder(
      itemCount: showUsers.length,
      itemBuilder: (context, index) {
        return followUserCard(
          username: showUsers[index]['username'],
        );
      },
    );
  }
}

//this is the UI for what the user follow UI should look like
class followUserCard extends StatefulWidget {
  String username;
  followUserCard({Key? key, required this.username}) : super(key: key);

  @override
  State<followUserCard> createState() => _followUserCardState();
}

class _followUserCardState extends State<followUserCard> {
  @override
  Widget build(BuildContext context) {
    late bool followed = !appBrain.followedUsers.contains(widget.username);
    print('${widget.username} and $followed');

    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          height: 80,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.all(Radius.circular(20))),
          child: Row(children: [
            const Icon(
              Icons.account_box,
              color: Colors.grey,
            ),
            const SizedBox(
              width: 10,
            ),
            Text(widget.username, style: const TextStyle(fontSize: 17)),
            const Spacer(),
            (widget.username == appBrain.loggedUser)
                ? GestureDetector(
                    onTap: (() {}),
                    child: Container(
                      width: 70,
                      height: 30,
                      decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          color: mainColor),
                      child: const Center(
                          child: Text(
                        'this is u',
                        style: TextStyle(color: Colors.white),
                      )),
                    ))
                : (!followed)
                    ? GestureDetector(
                        onTap: (() {
                          setState(() {
                            appBrain.unFollowUser(widget.username);
                            appBrain.followedUsers.remove(widget.username);
                            followed = false;
                          });
                        }),
                        child: Container(
                          width: 70,
                          height: 30,
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              color: mainColor),
                          child: const Center(
                              child: Text(
                            'following!',
                            style: TextStyle(color: Colors.white),
                          )),
                        ))
                    : GestureDetector(
                        onTap: (() {
                          setState(() {
                            appBrain.followUser(widget.username);
                            appBrain.followedUsers.add(widget.username);
                            followed = true;
                          });
                        }),
                        child: Container(
                          width: 70,
                          height: 30,
                          decoration: BoxDecoration(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                              color: mainColor),
                          child: const Center(
                              child: Text(
                            'follow',
                            style: TextStyle(color: Colors.white),
                          )),
                        ))
          ]),
        )
      ],
    );
  }
}
