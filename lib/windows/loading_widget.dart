/// Provides the [LoadingWidget] class.
import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('loading...'),
        ),
        body: const Text('The app is loading. Please wait.'));
  }
}
