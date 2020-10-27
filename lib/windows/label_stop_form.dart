/// Provides the [LabelStopForm] class.
import 'package:flutter/material.dart';

import '../labels_store.dart';
import '../stop.dart';

class LabelStopForm extends StatefulWidget {
  const LabelStopForm(this._stop, this._callback) : super();

  final Stop _stop;
  final void Function() _callback;

  @override
  LabelStopFormState createState() => LabelStopFormState(_stop, _callback);
}

class LabelStopFormState extends State<LabelStopForm> {
  LabelStopFormState(this._stop, this._callback) : super();

  final Stop _stop;
  final void Function() _callback;

  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: _stop.name);
  }

  @override
  Widget build(BuildContext context) {
    final Form form = Form(
      key: _key,
      child: ListView(
        children: <Widget>[
          TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'The name to display for this stop',
              ),
              validator: (String value) =>
                  value.isEmpty ? 'You must provide a value' : null),
          IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Text',
              onPressed: () => setState(() => _labelController.text = ''))
        ],
      ),
    );
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => Navigator.of(context).pop()),
          title: Text(_stop.realName),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
              onPressed: labels.hasLabel(_stop.code)
                  ? () {
                      labels.removeLabel(_stop.code);
                      Navigator.of(context).pop();
                      done();
                    }
                  : null,
            ),
            IconButton(
                icon: const Icon(Icons.save),
                tooltip: 'Save',
                onPressed: () {
                  if (_key.currentState.validate()) {
                    labels.addLabel(_stop.code, _labelController.text);
                    Navigator.of(context).pop();
                    done();
                  }
                })
          ],
        ),
        body: form);
  }

  @override
  void dispose() {
    super.dispose();
    _labelController.dispose();
  }

  void done() {
    labels.saveLabels();
    _callback();
  }
}
