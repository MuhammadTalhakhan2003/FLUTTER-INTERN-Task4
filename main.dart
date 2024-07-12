import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}

class ApiService {
  final String apiUrl = 'https://jsonplaceholder.typicode.com/posts';

  Future<List<Post>> fetchPosts() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Post.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }
}

class PostProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String _error = '';

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchPosts() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _posts = await _apiService.fetchPosts();
    } catch (e) {
      _error = 'Failed to load posts';
      _posts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PostProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JSONPlaceholder Posts',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: PostListScreen(),
      ),
    );
  }
}

class PostListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JSONPlaceholder Posts'),
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return Center(child: Text(provider.error));
          }

          if (provider.posts.isEmpty) {
            return Center(child: Text('No posts available.'));
          }

          return ListView.builder(
            itemCount: provider.posts.length,
            itemBuilder: (context, index) {
              final post = provider.posts[index];
              return Card(
                margin: EdgeInsets.all(10),
                elevation: 5,
                child: ListTile(
                  title: Text(post.title),
                  subtitle: Text(post.body),
                  leading: CircleAvatar(child: Text(post.id.toString())),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Provider.of<PostProvider>(context, listen: false).fetchPosts();
        },
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Posts',
      ),
    );
  }
}
