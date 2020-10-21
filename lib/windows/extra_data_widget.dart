/// Provides the [ExtraDataWidget] class.
import 'package:flutter/material.dart';

/// This is a class that allows displaying of arbitrary data without using a dialog.
class ExtraDataWidget extends StatelessWidget {
  const ExtraDataWidget(this.title, this.data);

  final String title;
  final Map<String, String> data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(title),
        ),
        body: ListView(
          children: data.entries
              .map<ListTile>((MapEntry<String, String> e) => ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value),
                  ))
              .toList(),
        ));
  }
}
