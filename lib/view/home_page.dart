import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_todo/services/model/todo.dart';
import 'package:flutter/material.dart';
import 'package:firebase_todo/services/authentication.dart';

class Homepage extends StatefulWidget {
  final BaseAuth auth;
  final VoidCallback singoutCallback;
  final String userid;

  const Homepage({Key key, this.auth, this.singoutCallback, this.userid})
      : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Todo> _todolist;
  Query _todoQuery;
  final _textEditingController = TextEditingController();

  StreamSubscription<Event> _onTodoAddedSubscription;
  StreamSubscription<Event> _onTodoChangedSubscription;

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  void initState() {
    super.initState();

    _todolist = new List();
    _todoQuery = _database
        .reference()
        .child("todo")
        .orderByChild("userId")
        .equalTo(widget.userid);
    _onTodoAddedSubscription = _todoQuery.onChildAdded.listen(onEntryAdded);
    _onTodoChangedSubscription =
        _todoQuery.onChildChanged.listen(onEntryChange);
  }

  onEntryChange(Event event) {
    var oldEntry = _todolist.singleWhere((element) {
      return element.key == event.snapshot.key;
    });
    setState(() {
      _todolist[_todolist.indexOf(oldEntry)] =
          Todo.fromSnapshot(event.snapshot);
    });
  }

  onEntryAdded(Event event) {
    setState(() {
      _todolist.add(Todo.fromSnapshot(event.snapshot));
    });
  }

  @override
  void dispose() {
    super.dispose();
    _onTodoChangedSubscription.cancel();
    _onTodoAddedSubscription.cancel();
  }

  addNewTodo(String todoItem) {
    if (todoItem.length > 0) {
      Todo todo = Todo(todoItem.toString(), false, widget.userid);
      _database.reference().child("todo").push().set(todo.toJson());
    }
  }

  updateTodo(Todo todo) {
    todo.completed = !todo.completed;
    if (todo != null) {
      _database.reference().child("todo").child(todo.key).set(todo.toJson());
    }
  }

  deleteTodo(String todoId, int index) {
    _database.reference().child("todo").child(todoId).remove().then((_) {
      setState(() {
        _todolist.removeAt(index);
      });
    });
  }

  signOut() async {
    try {
      await widget.auth.singOut();
      widget.singoutCallback();
    } catch (e) {
      print(e);
    }
  }

  Widget showTodoList() {
    if (_todolist.length > 0) {
      return ListView.builder(
          itemCount: _todolist.length,
          itemBuilder: (BuildContext context, int index) {
            String todoId = _todolist[index].key;
            String subject = _todolist[index].subject;
            bool completed = _todolist[index].completed;
            String userId = _todolist[index].userId;
            print(userId);

            return Dismissible(
                key: Key(todoId),
                background: Container(color: Colors.red),
                onDismissed: (direction) async {
                  deleteTodo(todoId, index);
                },
                child: ListTile(
                  title: Text(
                    subject,
                    style: TextStyle(fontSize: 20),
                  ),
                  trailing: IconButton(
                    onPressed: () {},
                    icon: (completed)
                        ? Icon(
                            Icons.done_outline,
                            color: Colors.green,
                            size: 20,
                          )
                        : Icon(
                            Icons.done_outline,
                            color: Colors.grey,
                            size: 20,
                          ),
                  ),
                ));
          });
    } else {
      return Center(
          child: Text(
        "Your list is empty.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30),
      ));
    }
  }

  showAddTodoDialog(BuildContext context) async {
    await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    autofocus: true,
                    decoration: InputDecoration(hintText: "Add new todo.."),
                  ),
                )
              ],
            ),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: (Text("Cancel")),
              ),
              FlatButton(
                  onPressed: () {
                    addNewTodo(_textEditingController.text.toString());
                    Navigator.pop(context);
                  },
                  child: Text('Save'))
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ToDo"),
        actions: [
          FlatButton(
              onPressed: signOut,
              child: Text(
                "Singout",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ))
        ],
      ),
      body: showTodoList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showAddTodoDialog(context);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
