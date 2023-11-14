import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  // Initialize the back4app api
  WidgetsFlutterBinding.ensureInitialized();
  const keyApplicationId = 'YOUR_APP_ID_HERE';
  const keyClientKey = 'YOUR_CLIENT_KEY_HERE';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, autoSendSessionId: true);

  // Start the application
  runApp(const TaskApp());
}

//==========================================
// APP ENTRY CLASS
//==========================================
class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const TaskHomePage(title: 'Task Home'),
    );
  }
}

//==========================================
// HOME PAGE WIDGET
//==========================================
class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key, required this.title});

  final String title;

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

//==========================================
// HOME PAGE STATE
//==========================================
class _TaskHomePageState extends State<TaskHomePage> {
  // Delete a task
  Future<void> deleteTask(String id) async {
    var task = ParseObject('Task')..objectId = id;
    await task.delete();
  }

  // Get all tasks
  Future<List<ParseObject>> getTasks() async {
    final QueryBuilder<ParseObject> parseQuery =
        QueryBuilder<ParseObject>(ParseObject('Task'));

    final ParseResponse apiResponse = await parseQuery.query();

    if (apiResponse.success && apiResponse.results != null) {
      // Let's show the results
      for (var o in apiResponse.results!) {
        if (kDebugMode) {
          print((o as ParseObject).toString());
        }
      }
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FutureBuilder<List<ParseObject>>(
            future: getTasks(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                case ConnectionState.waiting:
                  return const Center(
                    child: SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator()),
                  );
                default:
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Error..."),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(
                      child: Text("No Data..."),
                    );
                  } else {
                    return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          TaskItem task =
                              TaskItem.fromJson(snapshot.data![index]);
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black)),
                            child: ListTile(
                              title: task.buildTitle(context),
                              subtitle: task.buildDescription(context),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      // launch the update task page
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                UpdateTaskPage(task: task)),
                                      ).then((_) {
                                        setState(() {});
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      // delete task
                                      await deleteTask(task.getId(context));
                                      setState(() {
                                        const snackBar = SnackBar(
                                          content: Text("Task deleted!"),
                                          duration: Duration(seconds: 2),
                                        );
                                        ScaffoldMessenger.of(context)
                                          ..removeCurrentSnackBar()
                                          ..showSnackBar(snackBar);
                                      });
                                    },
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  }
              }
            }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // launch the create task page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateTaskPage()),
          ).then((shouldRefresh) {
            if (shouldRefresh) {
              setState(() {});
            }
          });
        },
        tooltip: 'Add task',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

//==========================================
// CREATE TASK PAGE
//==========================================
class CreateTaskPage extends StatelessWidget {
  CreateTaskPage({super.key});

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  Future<bool> addTask(BuildContext context) async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Empty title"),
        duration: Duration(seconds: 2),
      ));
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Empty Description"),
        duration: Duration(seconds: 2),
      ));
      return false;
    }
    var taskObject = ParseObject('Task')
      ..set('title', titleController.text)
      ..set('description', descriptionController.text);
    await taskObject.save();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create New Task'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a title',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Task description',
                ),
              ),
            ),
            Center(
                child: ElevatedButton(
              child: const Text('Add Task'),
              onPressed: () {
                addTask(context).then((val) {
                  if (val) {
                    Navigator.of(context).pop(true);
                  }
                });
              },
            )),
          ],
        ),
      ),
    );
  }
}

//==========================================
// UPDATE TASK PAGE
//==========================================
class UpdateTaskPage extends StatelessWidget {
  UpdateTaskPage({super.key, required this.task});

  final TaskItem task;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  Future<bool> updateTask(BuildContext context) async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Empty title"),
        duration: Duration(seconds: 2),
      ));
      return false;
    }
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Empty Description"),
        duration: Duration(seconds: 2),
      ));
      return false;
    }
    var taskObject = ParseObject('Task')
      ..objectId = task.id
      ..set('title', titleController.text)
      ..set('description', descriptionController.text);
    await taskObject.save();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Use the Todo to create the UI.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Update Task'),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextField(
                controller: titleController..text = task.title,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter a title',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                //initialValue: task.description,
                controller: descriptionController..text = task.description,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Task description',
                ),
              ),
            ),
            Center(
                child: ElevatedButton(
              child: const Text('Update Task'),
              onPressed: () {
                updateTask(context).then((val) {
                  if (val) {
                    Navigator.of(context).pop(true);
                  }
                });
              },
            )),
          ],
        ),
      ),
    );
  }
}

//==========================================
// TASK ITEM
//==========================================
class TaskItem {
  final String title;
  final String description;
  final String id;

  TaskItem(
    this.title,
    this.description,
    this.id,
  );

  Widget buildTitle(BuildContext context) => Text(title);

  Widget buildDescription(BuildContext context) => Text(description);

  String getId(BuildContext context) => id;

  static TaskItem fromJson(json) =>
      TaskItem(json['title'], json['description'], json['objectId']);
}
